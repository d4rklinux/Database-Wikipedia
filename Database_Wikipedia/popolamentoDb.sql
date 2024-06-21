-- Inserimento utente
INSERT INTO utente (username_utente, password, ruolo, nome, cognome, email)
VALUES
    ('denise.r', 'Password1.', 'Autore', 'Denise', 'Rossi', 'dn.rossi@studenti.unina.it'),
    ('giuseppe.i', 'Password2.', 'Autore', 'Giuseppe', 'izzo', 'gs.izzo@studenti.unina.it');
    ('francesco.e', 'Password3.', 'Utente', 'Francesco', 'Esposito', 'fr.esposito@studenti.unina.it'),

-- Per popolare il database utilizziamo direttamente la funzione inserisci_titolo_e_frasi()
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



-- Inserimento di un testo
DO $$ 
BEGIN
    PERFORM inserisci_titolo_e_frasi('Java (linguaggio di programmazione)', 'In informatica Java è un linguaggio di programmazione ad alto livello, orientato agli oggetti e a tipizzazione statica, che si appoggia sull omonima piattaforma software di esecuzione, specificamente progettato per essere il più possibile indipendente dalla piattaforma hardware di esecuzione (tramite compilazione in bytecode prima e interpretazione poi da parte di una JVM) (sebbene questa caratteristica comporti prestazioni in termini di computazione inferiori a quelle di linguaggi direttamente compilati come C e C++ ovvero dunque perfettamente adattati alla piattaforma hardware).Java è stato creato a partire da ricerche effettuate alla Stanford University agli inizi degli anni novanta. Nel 1992 nasce il linguaggio Oak (in italiano "quercia"), prodotto da Sun Microsystems e realizzato da un gruppo di esperti sviluppatori capitanati da James Gosling. Questo nome fu successivamente cambiato in Java (una varietà di caffè indonesiana; il logo adottato è una tazzina per tale bevanda) per problemi di copyright: il linguaggio di programmazione Oak esisteva già.Per facilitare il passaggio a Java ai programmatori old-fashioned, legati in particolare a linguaggi come il C++, la sintassi di base (strutture di controllo, operatori ecc.) è stata mantenuta pressoché identica a quella del C++; tuttavia a livello di linguaggio non sono state introdotte caratteristiche ritenute fonte di complessità non necessaria e che favoriscono l introduzione di determinati bug durante la programmazione, come l aritmetica dei puntatori e l ereditarietà multipla delle classi. Per le caratteristiche orientate agli oggetti del linguaggio ci si è ispirati al C++ e soprattutto all Objective C.In un primo momento Sun decise di destinare questo nuovo prodotto alla creazione di applicazioni complesse per piccoli dispositivi elettronici; fu solo nel 1993 con l esplosione di internet che Java iniziò a farsi notare come strumento per iniziare a programmare per internet. Contemporaneamente Netscape Corporation annunciò la scelta di dotare il suo allora omonimo e celeberrimo browser della Java Virtual Machine (JVM). Questo segna una rivoluzione nel mondo di Internet: grazie agli applet le pagine web diventarono interattive a livello client, ovvero le applicazioni vengono eseguite direttamente sulla macchina dell utente di internet e non su un server remoto. Per esempio gli utenti poterono utilizzare giochi direttamente sulle pagine web e usufruire di chat dinamiche e interattive.Java fu annunciato ufficialmente il 23 maggio 1995 a SunWorld. Il 13 novembre 2006 la Sun Microsystems ha distribuito la sua implementazione del compilatore Java e della macchina virtuale sotto licenza GPL. Non tutte le piattaforme Java sono libere. L ambiente Java libero si chiama IcedTea. L 8 maggio 2007 Sun ha pubblicato anche le librerie, tranne alcuni componenti non di sua proprietà, sotto licenza GPL, rendendo Java un linguaggio di programmazione la cui implementazione di riferimento è libera. Il linguaggio è definito da un documento chiamato The Java Language Specification, spesso abbreviato JLS. La prima edizione del documento è stata pubblicata nel 1996. Da allora il linguaggio ha subito numerose modifiche e integrazioni, aggiunte di volta in volta nelle edizioni successive. A fine 2022 la versione più recente delle specifiche è la Java SE 19 Edition.', 'ale.m');
END $$;


-- Inserimento di un testo
DO $$ 
BEGIN
    PERFORM inserisci_titolo_e_frasi('Lorem ipsum','Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
    Pellentesque accumsan magna at justo gravida eleifend at eu eros. Mauris eu nisl aliquam, tristique arcu id, 
    hendrerit quam. Sed quis ligula eu tortor pellentesque rutrum ac auctor mauris. Aenean malesuada nec augue facilisis porttitor. 
    Donec nec feugiat dui. Etiam non imperdiet nunc, sed mattis lectus. Suspendisse vulputate eu nisl id ullamcorper. Nulla 
    tempus aliquam mauris, at condimentum est sollicitudin non. Nam faucibus dui ut nunc placerat, sed vehicula augue fringilla. 
    Ut ac quam id ex iaculis ornare. Aliquam felis ex, pharetra eget dui in, gravida rhoncus risus. Maecenas vel pharetra ante, et 
    consectetur purus.Pellentesque laoreet sed ex eget bibendum. Integer ut ultricies arcu. Suspendisse suscipit pharetra eros, 
    vitae euismod dui interdum eget. In bibendum at diam at egestas. Pellentesque eu ante vitae risus mollis condimentum. Integer 
    ullamcorper lacus ac tincidunt euismod. Integer a velit quis risus cursus mattis. Sed a magna nunc. Donec laoreet suscipit 
    ultricies. Nullam euismod est quis velit luctus vulputate.Integer vel gravida justo, sit amet ultrices ipsum. Morbi at laoreet 
    turpis, non tincidunt sapien. In hac habitasse platea dictumst. Nullam dignissim ultricies quam vel eleifend. Donec sagittis, 
    leo id maximus tincidunt, purus nibh aliquam sapien, eget dapibus nisl ante sit amet ipsum. Pellentesque finibus tortor tortor,
     ornare tincidunt quam vulputate at. Pellentesque sit amet dolor a erat sodales aliquam. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse ut 
     vestibulum eros. Nunc et tempus urna. Duis lectus nibh, bibendum eu mi vel, pulvinar dignissim augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; 
     Proin posuere gravida augue ac gravida. Nullam et volutpat purus.

','romi.i');


END $$;

-- Inserimento di un testo
DO $$ 
BEGIN
    PERFORM inserisci_titolo_e_frasi('Base di dati','In informatica una base di dati, detta anche, dall inglese, database o data base, o anche banca dati, è una collezione di dati organizzati immagazzinata e accessibile per via elettronica. 
Nel linguaggio comune e informale, la locuzione database tende ad essere utilizzata impropriamente con varie sfumature di significato, di ordine più generale rispetto a "collezione astratta di dati": 
•	database server: ovvero il sistema fisico, comprendente sia le risorse di elaborazione che di memorizzazione necessarie al funzionamento della base di dati.
•	database management system: ovvero il sistema software necessario all interfacciamento con la base di dati.
La progettazione delle basi di dati è un attività complessa, che si basa sull applicazione di tecniche formali in congiunzione a considerazioni pratiche derivate dalla natura dei dati stessi. In fase di progettazione si affrontano quindi problemi in materia di modellazione, rappresentazione, archiviazione e accesso ai dati, oltre che della loro sicurezza, privatezza ed integrità. Senza contare altre questioni di contorno che pertengono più propriamente ai DBMS.All inizio della storia dell informatica, la grande maggioranza dei programmi specializzati consentivano l accesso a una singola base di dati per guadagnare in velocità di esecuzione, pur perdendo in flessibilità. Oggi, invece, i moderni sistemi possono essere utilizzati per compiere operazioni su un gran numero di basi di dati differenti. Dagli anni settanta del XX secolo le basi di dati hanno subito un enorme sviluppo sia in fatto di quantità di dati memorizzati sia in fatto di tipi di architetture adottate.

Le basi di dati relazionali diventarono predominanti negli anni 80. Queste modellano i dati come righe e colonne in una serie di tabelle, e la stragrande maggioranza utilizza SQL come linguaggio di interrogazione. Negli anni 2000, presero piede anche modelli non relazionali, collettivamente chiamati NoSQL, perché generalmente adottano linguaggi diversi dal SQL.'
    ,'ale.m');


END $$;

-- Invio proposta
INSERT INTO proposta (vecchio_contenuto, nuovo_contenuto, stato, id_frase, ora_proposta, data_proposta, username_utente_proposta)
VALUES
    ('Lorem ipsum dolor sit amet, consectetur adipiscing elit', 'NuovoContenuto1', 'In attesa', 21, '12:30:00', '2024-02-02', 'cri.m'),
    ('Le basi di dati relazionali diventarono predominanti negli anni 80', 'NuovoContenuto2', 'In attesa', 82, '14:45:00', '2024-02-03', 'cri.m');


-- Collegamento all'interno di pagina
INSERT INTO collegamento (id_pagina, id_frase, URL)
VALUES
    (1, 1, 'https://it.wikipedia.org/wiki/Java_(linguaggio_di_programmazione)'),
    (2, 21, 'https://it.lipsum.com/');
	(3, 71, 'https://it.wikipedia.org/wiki/Base_di_dati');


    -- La tabella modifica si aggiorna automaticamento dopo un update della tabella proposta,rifiutando o accettando
