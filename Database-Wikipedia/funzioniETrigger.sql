CREATE OR REPLACE FUNCTION inserisci_titolo_e_frasi(
    titolo_input VARCHAR(20),
    testo_input TEXT,
    username_autore_input VARCHAR(15))
RETURNS VOID AS $$
DECLARE
    id_pagina_new INT;
    id_frase_new INT;
    id_testo_new INT;
    frase_parti TEXT[];
    frase_parte TEXT;
BEGIN
    -- Inserisci il titolo nella tabella pagina
    INSERT INTO pagina (titolo, data_creazione, ora_creazione, username_autore)
    VALUES (titolo_input, CURRENT_DATE, CURRENT_TIME, username_autore_input)
    RETURNING id_pagina INTO id_pagina_new;

    -- Inserisci il testo associato alla pagina nella tabella testo
    INSERT INTO testo (id_pagina)
    VALUES (id_pagina_new)
    RETURNING id_testo INTO id_testo_new;

    -- Divide il testo in frasi usando sia il punto che il carattere di a capo come delimitatori
    frase_parti := regexp_split_to_array(testo_input, '[.\n]+');

    -- Rimuovi eventuali stringhe vuote dall'array
    frase_parti := array_remove(frase_parti, '');

    -- Inserisci ogni frase nella tabella frase
    FOREACH frase_parte IN ARRAY frase_parti
    LOOP
        -- Rimuovi eventuali spazi iniziali e finali
        frase_parte := trim(frase_parte);

        -- Inserisci la frase nella tabella frase
        INSERT INTO frase (contenuto_frase, versione, id_pagina, id_testo)
        VALUES (frase_parte, 1, id_pagina_new, id_testo_new)
        RETURNING id_frase INTO id_frase_new;

        -- Fai qualcos'altro con id_frase_new se necessario
    END LOOP;

    -- Esempio: Aggiungi un log delle frasi inserite
    RAISE NOTICE 'Inserite % frasi per la pagina %', array_length(frase_parti, 1), titolo_input;

    -- Esempio: Restituisci un messaggio di successo
    RAISE NOTICE 'Pagina "%", titolo "%", inserita con successo.', id_pagina_new, titolo_input;

END;
$$ LANGUAGE plpgsql;




SELECT inserisci_titolo_e_frasi('Titolo di Esempio', 'Prima frase. Seconda frase.', 'nome_utente');


----------------





CREATE OR REPLACE FUNCTION check_autore_per_pagina()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT ruolo FROM utente WHERE username_utente = NEW.username_autore) != 'Autore' THEN
        RAISE EXCEPTION 'Solo gli autori possono creare pagine.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_autore_per_pagina
BEFORE INSERT ON pagina
FOR EACH ROW
EXECUTE FUNCTION check_autore_per_pagina();



-- Creazione della funzione per il trigger
CREATE OR REPLACE FUNCTION before_insert_utente()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM utente WHERE username_utente = NEW.username_utente) THEN
        RAISE EXCEPTION 'L''utente con username % è già registrato', NEW.username_utente;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creazione del trigger
CREATE TRIGGER before_insert_utente_trigger
BEFORE INSERT
ON utente
FOR EACH ROW
EXECUTE FUNCTION before_insert_utente();


----------------------------------------------------------------



CREATE OR REPLACE FUNCTION trigger_prevent_data_ora_futura()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.data_creazione > CURRENT_DATE THEN
        RAISE EXCEPTION 'Impossibile creare una pagina con data di creazione futura.';
    ELSIF NEW.data_creazione = CURRENT_DATE AND NEW.ora_creazione > CURRENT_TIME THEN
        RAISE EXCEPTION 'Impossibile creare una pagina con data e ora di creazione future.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_prevent_data_ora_futura
BEFORE INSERT ON pagina
FOR EACH ROW
EXECUTE FUNCTION trigger_prevent_data_ora_futura();


------------------------------
CREATE OR REPLACE FUNCTION visualizza_frasi_per_pagina(
    titolo_input VARCHAR(20))
RETURNS TABLE (
    contenuto_frase VARCHAR,
    versione INT,
    data_creazione DATE,
    ora_creazione TIME,
    autore_frase VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.contenuto_frase,
        f.versione,
        p.data_creazione,
        p.ora_creazione,
        p.username_autore AS autore_frase
    FROM
        pagina p
    JOIN
        frase f ON p.id_pagina = f.id_pagina
    WHERE
        p.titolo = titolo_input
    ORDER BY
        f.id_frase; -- Ordina per id_frase invece che per versione
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION public.check_vecchio_contenuto_exists(
	p_id_frase integer,
	p_vecchio_contenuto character varying)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    contenuto_attuale VARCHAR;
BEGIN
    -- Ottieni il contenuto attuale della frase
    SELECT contenuto_frase INTO contenuto_attuale
    FROM frase
    WHERE id_frase = p_id_frase;

    -- Restituisci true se il vecchio_contenuto corrisponde al contenuto attuale
    RETURN contenuto_attuale = p_vecchio_contenuto;
END;
$BODY$;


CREATE OR REPLACE FUNCTION public.trigger_elimina_proposte_in_attesa()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    -- Se la proposta è stata accettata e lo stato precedente era "In attesa"
    IF NEW.stato = 'Accettata' AND COALESCE(OLD.stato, 'In attesa') = 'In attesa' THEN
        -- Qui eliminiamo tutte le proposte in attesa tranne quella accettata
        DELETE FROM proposta
        WHERE id_frase = NEW.id_frase AND stato = 'In attesa' AND id_proposta <> NEW.id_proposta;
    END IF;

    RETURN NEW;
END;
$BODY$;

CREATE TRIGGER trigger_elimina_proposte_in_attesa
AFTER UPDATE ON proposta
FOR EACH ROW
EXECUTE FUNCTION public.trigger_elimina_proposte_in_attesa();



CREATE OR REPLACE FUNCTION public.check_autore_per_pagina()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
    IF (SELECT ruolo FROM utente WHERE username_utente = NEW.username_autore) != 'Autore' THEN
        RAISE EXCEPTION 'Solo gli autori possono creare pagine.';
    END IF;
    RETURN NEW;
END;
$BODY$;

CREATE TRIGGER before_insert_pagina
BEFORE INSERT ON pagina
FOR EACH ROW
EXECUTE FUNCTION public.check_autore_per_pagina();




CREATE OR REPLACE FUNCTION trova_id_frase_con_titolo(
    IN titolo_pagina VARCHAR,
    IN vecchio_contenuto_frase VARCHAR
)
RETURNS INT
AS $$
DECLARE
    frase_id INT;
BEGIN
    SELECT f.id_frase INTO frase_id
    FROM frase f
    JOIN pagina p ON f.id_pagina = p.id_pagina
    WHERE p.titolo = titolo_pagina
        AND f.contenuto_frase = vecchio_contenuto_frase;

    RETURN frase_id;
END;
$$ LANGUAGE plpgsql;





CREATE OR REPLACE FUNCTION public.trigger_incrementa_versione()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    NEW.versione := COALESCE(OLD.versione, 0) + 1;
    RETURN NEW;
END;
$$;

CREATE TRIGGER before_update_frase
BEFORE UPDATE ON frase
FOR EACH ROW
EXECUTE FUNCTION public.trigger_incrementa_versione();




CREATE OR REPLACE FUNCTION public.get_proposte_ordered_by_data_ora(
    autore_destinatario varchar(15)
)
RETURNS TABLE(
    id_proposta integer,
    vecchio_contenuto varchar(255),
    nuovo_contenuto varchar(255),
    stato stato_proposta,
    id_frase integer,
    ora_proposta time without time zone,
    data_proposta date,
    username_utente_proposta varchar(15),
    titolo_pagina varchar(20),
    autore_pagina varchar(15)
) 
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
ROWS 1000
AS $BODY$
BEGIN
    RETURN QUERY
    SELECT
        p.id_proposta,
        p.vecchio_contenuto,
        p.nuovo_contenuto,
        p.stato,
        p.id_frase,
        p.ora_proposta,
        p.data_proposta,
        p.username_utente_proposta,
        pa.titolo AS titolo_pagina,
        ua.username_utente AS autore_pagina
    FROM
        proposta AS p
    INNER JOIN frase AS f ON p.id_frase = f.id_frase
    INNER JOIN pagina AS pa ON f.id_pagina = pa.id_pagina
    INNER JOIN utente AS ua ON pa.username_autore = ua.username_utente
    -- Rimuovi la condizione di filtro sull'autore
    -- WHERE
    --     p.username_utente_proposta = autore_destinatario
    ORDER BY
        p.data_proposta ASC,
        p.ora_proposta ASC;
END;
$BODY$;






CREATE OR REPLACE FUNCTION after_update_proposta_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Se la proposta è accettata, aggiorna il contenuto della frase
    IF NEW.stato = 'Accettata' THEN
        UPDATE frase
        SET contenuto_frase = NEW.nuovo_contenuto
        WHERE id_frase = OLD.id_frase;  -- Utilizza l'ID della frase precedente (OLD)

       
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER after_update_proposta
AFTER UPDATE ON proposta
FOR EACH ROW
WHEN (OLD.stato IS DISTINCT FROM NEW.stato)
EXECUTE FUNCTION after_update_proposta_trigger();



-- Funzione per trigger dopo l'aggiornamento su proposta
CREATE OR REPLACE FUNCTION post_update_proposta_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Inserisci una nuova riga nella tabella modifica
    INSERT INTO modifica (id_proposta, username_utente, stato)
    VALUES (NEW.id_proposta, NEW.username_utente_proposta, NEW.stato);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger dopo l'aggiornamento su proposta
CREATE TRIGGER post_update_proposta
AFTER UPDATE ON proposta
FOR EACH ROW
WHEN (OLD.stato IS DISTINCT FROM NEW.stato)
EXECUTE FUNCTION post_update_proposta_trigger();




CREATE OR REPLACE FUNCTION calcola_ratio_modifiche(username_utente_input VARCHAR(15))
RETURNS DECIMAL(10,2) AS $$
DECLARE
    total_modifiche INT;
    modifiche_accettate INT;
    ratio DECIMAL(10,2);
BEGIN
    -- Calcola il totale delle modifiche fatte dall'utente
    SELECT COUNT(*) INTO total_modifiche
    FROM modifica
    WHERE username_utente = username_utente_input;

    -- Calcola il totale delle modifiche accettate dall'utente
    SELECT COUNT(*) INTO modifiche_accettate
    FROM modifica
    WHERE username_utente = username_utente_input AND stato = 'Accettata';

    -- Calcola il rapporto tra modifiche accettate e totale modifiche
    IF total_modifiche > 0 THEN
        ratio := modifiche_accettate / total_modifiche;
    ELSE
        ratio := 0;
    END IF;

    RETURN ratio;
END;
$$ LANGUAGE PLpgSQL;



CREATE OR REPLACE FUNCTION calcola_totale_pagine_autore(username_autore_input VARCHAR(15))
RETURNS INT AS $$
DECLARE
    total_pagine INT;
BEGIN
    -- Calcola il totale delle pagine realizzate dall'autore
    SELECT COUNT(*) INTO total_pagine
    FROM pagina
    WHERE username_autore = username_autore_input;

    RETURN total_pagine;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION public.modifica_diretta_frase(
    p_id_frase integer,
    p_nuovo_contenuto character varying,
    p_username_autore character varying)
RETURNS void
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
    -- Verifica se l'utente è un autore
    IF EXISTS (
        SELECT 1
        FROM utente
        WHERE username_utente = p_username_autore AND ruolo = 'Autore'
    ) THEN
        -- Effettua la modifica diretta della frase
        BEGIN
            UPDATE frase
            SET contenuto_frase = p_nuovo_contenuto
            WHERE id_frase = p_id_frase;
        EXCEPTION
            WHEN others THEN
                -- Gestisci le eccezioni se l'aggiornamento fallisce
                RAISE EXCEPTION 'Errore durante l''aggiornamento della frase: %', SQLERRM;
        END;
    ELSE
        -- L'utente non è un autore, verifica la proposta
        IF EXISTS (
            SELECT 1
            FROM frase AS f
            WHERE f.id_frase = p_id_frase AND f.username_autore = p_username_autore
        ) THEN
            -- Accetta la proposta
            -- Aggiorna la frase con il nuovo contenuto
            BEGIN
                UPDATE frase
                SET contenuto_frase = p_nuovo_contenuto
                WHERE id_frase = p_id_frase;
            EXCEPTION
                WHEN others THEN
                    -- Gestisci le eccezioni se l'aggiornamento fallisce
                    RAISE EXCEPTION 'Errore durante l''aggiornamento della frase: %', SQLERRM;
            END;
        ELSE
            -- L'utente non è autorizzato a modificare questa frase
            RAISE EXCEPTION 'L''utente % non è autorizzato a modificare la frase %', p_username_autore, p_id_frase;
        END IF;
    END IF;
END;
$BODY$;




CREATE OR REPLACE FUNCTION public.after_insert_proposta()
RETURNS TRIGGER
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    -- Chiamiamo la funzione di modifica dopo un inserimento in proposta
    PERFORM public.modifica_diretta_frase(NEW.id_frase, NEW.nuovo_contenuto, NEW.username_utente_proposta);

    RETURN NEW;
END;
$BODY$;

CREATE TRIGGER trigger_after_insert_proposta
AFTER INSERT ON proposta
FOR EACH ROW
EXECUTE FUNCTION public.after_insert_proposta();
