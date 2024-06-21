CREATE TYPE stato_proposta AS ENUM ('Accettata', 'Rifiutata','In attesa');


CREATE TABLE utente (
    username_utente varchar(15) NOT NULL,
    password varchar(15) NOT NULL,
    ruolo varchar(6) NOT NULL,
    nome varchar(20) NOT NULL,
    cognome varchar(20) NOT NULL,
    email varchar(255),
    PRIMARY KEY (username_utente)
);

CREATE TABLE pagina (
    id_pagina SERIAL PRIMARY KEY,
    titolo VARCHAR(100) NOT NULL,
    data_creazione DATE,
    ora_creazione TIME,
    username_autore VARCHAR(15),
    FOREIGN KEY (username_autore) REFERENCES utente(username_utente) ON DELETE CASCADE
);
CREATE TABLE testo (
    id_testo SERIAL  PRIMARY KEY,
    id_pagina Int,
    FOREIGN KEY (id_pagina) REFERENCES pagina(id_pagina) ON DELETE CASCADE
);



CREATE TABLE frase (
    Id_frase SERIAL PRIMARY KEY,
    contenuto_frase VARCHAR,
    versione int,
    id_pagina int,
    id_testo int,
    FOREIGN KEY (id_pagina) REFERENCES pagina(id_pagina) ON DELETE CASCADE,
    FOREIGN KEY (id_testo) REFERENCES testo(id_testo) ON DELETE CASCADE
);

CREATE TABLE proposta (
    id_proposta SERIAL PRIMARY KEY,
    vecchio_contenuto VARCHAR(255),
    nuovo_contenuto VARCHAR(255),
    stato stato_proposta,
    id_frase int,
ora_proposta TIME,
data_proposta DATE,
username_utente_proposta VARCHAR(15),
    FOREIGN KEY (id_frase) REFERENCES frase(id_frase) ON DELETE CASCADE,
    FOREIGN KEY (username_utente_proposta) REFERENCES utente(username_utente) ON DELETE CASCADE
);

CREATE TABLE modifica (
    id_proposta INT NOT NULL,
    username_utente VARCHAR(15) NOT NULL,
    stato stato_proposta,
    PRIMARY KEY (id_proposta, username_utente,stato),
    FOREIGN KEY (id_proposta) REFERENCES proposta(id_proposta) ON DELETE CASCADE,
    FOREIGN KEY (username_utente) REFERENCES utente(username_utente) ON DELETE CASCADE
);

CREATE TABLE collegamento (
    id_pagina INT NOT NULL,
    id_frase INT NOT NULL,
URL VARCHAR (100) PRIMARY KEY,
    FOREIGN KEY (id_pagina) REFERENCES pagina(id_pagina) ON DELETE CASCADE,
     FOREIGN KEY (id_frase) REFERENCES frase(id_frase) ON DELETE CASCADE
    
);




-- Aggiungi un vincolo di unicità sulla colonna 'email' nella tabella 'utente'
ALTER TABLE utente
ADD CONSTRAINT uk_email UNIQUE (email);

-- Aggiungi un vincolo di check sulla colonna 'ruolo' nella tabella 'utente'
-- che accetta solo valori 'Autore' o 'Utente'
ALTER TABLE utente
ADD CONSTRAINT chk_ruolo CHECK (ruolo IN ('Autore', 'Utente'));

-- Rendi la colonna 'nome' nella tabella 'utente' non nulla (NOT NULL)
ALTER TABLE utente
ALTER COLUMN nome SET NOT NULL;

-- Aggiungi un vincolo di check sulla colonna 'data_creazione' nella tabella 'pagina'
-- che assicura che la data di creazione non sia successiva alla data corrente
ALTER TABLE pagina
ADD CONSTRAINT chk_data_creazione CHECK (data_creazione <= CURRENT_DATE);

-- Aggiungi un vincolo di check sulla tabella 'proposta'
-- che assicura che 'vecchio_contenuto' e 'nuovo_contenuto' siano diversi
ALTER TABLE proposta
ADD CONSTRAINT chk_vecchio_nuovo_contenuto_different
CHECK (vecchio_contenuto <> nuovo_contenuto);

-- Imposta il valore di default 'In attesa' per la colonna 'stato' nella tabella 'proposta'
ALTER TABLE proposta
ALTER COLUMN stato SET DEFAULT 'In attesa';

-- Aggiungi un vincolo di unicità sulla colonna 'titolo' nella tabella 'pagina'
ALTER TABLE pagina
ADD CONSTRAINT uk_titolo UNIQUE (titolo);

-- Ottieni la sequenza associata alla colonna 'id_pagina' nella tabella 'pagina'
SELECT pg_get_serial_sequence('pagina', 'id_pagina');

-- Riavvia la sequenza associata a 'id_pagina' nella tabella 'pagina' impostando il valore a 1
ALTER SEQUENCE public.pagina_id_pagina_seq RESTART WITH 1;

-- Simili comandi per le sequenze di altre tabelle come 'testo', 'frase', e 'proposta'
SELECT pg_get_serial_sequence('testo', 'id_testo');
ALTER SEQUENCE public.testo_id_testo_seq RESTART WITH 1;

SELECT pg_get_serial_sequence('frase', 'id_frase');
ALTER SEQUENCE public.frase_id_frase_seq RESTART WITH 1;

SELECT pg_get_serial_sequence('proposta', 'id_proposta');
ALTER SEQUENCE public.proposta_id_proposta_seq RESTART WITH 1;
