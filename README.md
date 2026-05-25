# Zálohování výrobních počítačů pomocí Acronis Cyber Protect Cloud, lokálního NAS Synology a cloudové replikace

Výrobní počítače mají často specifické konfigurace, starší operační systémy, lokální aplikace, licence, ovladače nebo napojení na technologii. A právě v takovém prostředí se vyplatí zamyslet se nad celým pojetím konceptu zálohování.

Na základě reálných zkušeností jsem dal dohromady praktický white paper / best practice k nasazení Acronis Cyber Protect Cloud v kombinaci s lokálním NAS Synology a selektivní replikací do Acronis Cloudu.
Vychází z reálných poznatků, konkrétních scénářů, testů obnovy a otázek, které se při implementaci řešení Acronis opravdu řeší, namátkou: kapacita NAS, objem dat, RTO/RPO, ochranné plány, cloudová replikace, immutable snapshots, obnova výrobního PC i předimplementační analýza dat k zálohování pomocí PowerShellu.

Dokument popisuje přístup vhodný pro prostředí, kde existuje více výrobních lokalit, stovky výrobních počítačů, omezená cloudová kapacita, omezená WAN konektivita a reálný požadavek na rychlou lokální obnovu. Nemá za cíl být detailním návodem nebo postupem krok za krokem a v detailu vše popsat, spíše poskytnout celkový přehled s kroky, které se vyplatí nepodceňovat. 

Přiložené PowerShell skripty řeší extrakci informací o lokálních discích a operačním systému v prostředí Active Directory. Jejich použití je na vlastní riziko. 
