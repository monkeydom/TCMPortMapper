#!/usr/bin/env ruby

require 'json'

old_basename = "OUItoCompany"
new_basename = "OUItoCompany2Level"
other_basename = "OUItoCompanyShort"

umlautfixes = {
	"bioM?rieux Italia S.p.A" => "bioMérieux Italia S.p.A",
	"Instituto Nacional de Tecnolog?a" => "Instituto Nacional de Tecnologia",
	"Burg-W?Chter" => "Burg-Wächter",
	"B?rkert Werke" => "Bürkert Werke",
	"Weinmann Ger?te f?r Medizin +" => "Weinmann Geräte für Medizin +",
	"S I Sistemas Inteligentes Eletr?nicos" => "S I Sistemas Inteligentes Eletrônicos",
	"Fins?cur" => "Finsecur",
	"CAMCO Produktions- und Vertriebs-GmbH f?r Beschallungs- und Beleuchtungsanlagen" => "CAMCO Produktions- und Vertriebs-GmbH für Beschallungs- und Beleuchtungsanlagen",
	"GEMAC Gesellschaft f?r Mikroelektronikanwendung Chemnitz mbH" => "GEMAC Gesellschaft für Mikroelektronikanwendung Chemnitz mbH",
	"R. STAHL Schaltger?te" => "R. STAHL Schaltgeräte",
	"Tellink Sistemas de Telecomunicaci?n S.L" => "Tellink Sistemas de Telecomunicación S.L",
	"Redes de Telefon?a M?vil S.A" => "Redes de Telefon?a M?vil S.A",
	"Oc? Document" => "Oc? Document",
	"GAMESA E?lica" => "GAMESA E?lica",
	"Aglaia Gesellschaft f?r Bildverarbeitung und Kommunikation mbH" => "Aglaia Gesellschaft für Bildverarbeitung und Kommunikation mbH",
	"Industria Fueguina de Relojer?a Electr?nica s.a" => "Industria Fueguina de Relojer?a Electr?nica s.a",
	"Objetivos y Servicio de Valor A?adido" => "Objetivos y Servicio de Valor A?adido",
	"Kael M?Hend?SL?K Elektron?K T?Caret Sanay? L?M?TED ??Rket?" => "Kael M?Hend?SL?K Elektron?K T?Caret Sanay? L?M?TED ??Rket?",
	"Daruma Telecomunica??es e Inform?tica S.A" => "Daruma Telecomunica??es e Inform?tica S.A",
	"Visiontec da Amaz?nia" => "Visiontec da Amaz?nia",
	"Companytec automa??o e Controle" => "Companytec automa??o e Controle",
	"Nordwestdeutsche Z?hlerrevision" => "Nordwestdeutsche Zählerrevision",
	"Institut f?r Pr?ftechnik" => "Institut f?r Pr?ftechnik",
	"Synapse ?lectronique" => "Synapse ?lectronique",
	"Tr?pico Sistemas e Telecomunica??es da Amaz?nia" => "Tr?pico Sistemas e Telecomunica??es da Amaz?nia",
	"A Beltr?nica-Companhia de Comunica??es" => "A Beltr?nica-Companhia de Comunica??es",
	"Weidm?ller Interface" => "Weidm?ller Interface",
	"Hesch Schr?der" => "Hesch Schr?der",
	"Friedrich L?tze" => "Friedrich L?tze",
	"Kn?rr" => "Kn?rr",
	"F?lt" => "F?lt",
	"Automat Engenharia de Automa??o" => "Automat Engenharia de Automa??o",
	"Helmut Fischer Institut f?r Elektronik und Messtechnik" => "Helmut Fischer Institut für Elektronik und Messtechnik",
	"Elsys Equipamentos Eletr?nicos" => "Elsys Equipamentos Eletrônicos",
	"Assa Abloy C?TE Picarde" => "Assa Abloy C?TE Picarde",
	"??????????" => "??????????",
	"Wa?chter Sicherheitssysteme" => "Wa?chter Sicherheitssysteme",
	"Firemax?Stria E CoM?Rcio de Produtos Eletr?Nicos" => "Firemax Indústria e Comércio de Produtos Eletrônicos",
	"IMS Solu??es em Energia" => "IMS Solu??es em Energia",
	"Sistemas de Gesti?n Energ?tica S.A. de C.V" => "Sistemas de Gestión Energética S.A. de C.V",
	"Neuberger Geb?udeautomation" => "Neuberger Gebäudeautomation",
	"Kr?ger &Gothe" => "Krüger & Gothe",
	"Tecvan Inform?tica" => "Tecvan Informática",
	"?mic" => "?mic",
	"Almitec Inform?tica e Com?rcio" => "Almitec Informática e Comércio",
	"Geutebr?ck" => "Geutebrück",
	"B?chi Labortechnik" => "Büchi Labortechnik",
	"Mil?nio 3 Sistemas Electr?nicos" => "Milénio 3 Sistemas Electrônicos",
	"Ing. B?ro Dr. Beutlhauser" => "Ing. Büro Dr. Beutlhauser",
	"Vestel Elektronik San ve Tic. A.?" => "Vestel Elektronik San ve Tic. A.Ş.",
	"Sncf Mobilit?S" => "Sncf Mobilité",
	"Edata Elektronik San. ve Tic. A.?" => "Edata Elektronik San. ve Tic. A.Ş.",
	"PENTA Gesellschaft f?r elektronische Industriedatenverarbeitung mbH" => "PENTA Gesellschaft für elektronische Industriedatenverarbeitung mbH",
	"Stage Tec Entwicklungsgesellschaft f?r professionelle Audiotechnik mbH" => "Stage Tec Entwicklungsgesellschaft für professionelle Audiotechnik mbH",
	"Furukawa S.A. Produtos El?tricos" => "Furukawa S.A. Produtos El?tricos",
	"EFR Europ?ische Funk-Rundsteuerung" => "EFR Europäische Funk-Rundsteuerung",
	"ITF Fr?schl" => "ITF Fröschl",
	"All Earth Com?rcio de Eletr?nicos" => "All Earth Comércio de Eletrônicos",
	"Excito Elektronik i Sk?ne" => "Excito Elektronik i Skåne",
	"Adam Elektronik ?TI" => "Adam Elektronik ŞTI",
	"EMS Dr. Thomas W?nsche" => "EMS Dr. Thomas Wünsche",
	"Pr?ftechnik Condition Monitoring" => "Prüftechnik Condition Monitoring",
	"Werbeagentur J?rgen Siebert" => "Werbeagentur Jürgen Siebert",
	"Universal de Desarrollos Electr?Nicos" => "Universal de Desarrollos Electr?Nicos",
	"H. Schom?cker" => "H. Schomäcker",
	"BSH Hausger?te" => "BSH Hausgeräte",
	"Securitas Direct Espa?A" => "Securitas Direct España",
	"PT Inova??o e Sistemas" => "PT Inovação e Sistemas",
	"Objetivos y Sevicios de Valor An?adido" => "Objetivos y Sevicios de Valor Añadido",
	"Elektronik System i Ume?" => "Elektronik System i Umeå",
	"GFR Gesellschaft f?r Regelungstechnik und Energieeinsparung mbH" => "GFR Gesellschaft für Regelungstechnik und Energieeinsparung mbH",
	"Dr?gerwerk &. aA" => "Drägerwerk AG",
	"Fagor Electr?nica" => "Fagor Electr?nica",
	"IRCO Sistemas de Telecomunicaci?n S.A" => "IRCO Sistemas de Telecomunicación S.A",
	"DLG Automa??o" => "DLG Automação",
	"GSI Helmholtzzentrum f?r Schwerionenforschung" => "GSI Helmholtzzentrum für Schwerionenforschung",
	"J?ger Computergesteuerte Messtechnik" => "Jäger Computergesteuerte Messtechnik",
	"Proview Eletr?nica do Brasil" => "Proview Eletrônica do Brasil",
	"Nextvision Sistemas Digitais de Televis?O" => "Nextvision Sistemas Digitais de Televisão",
	"Ex?ns Development" => "Exens Development",
	"Profilo Telra Elektronik Sanayi ve Ticaret. A.?" => "Profilo Telra Elektronik Sanayi ve Ticaret. A.Ş.",
	"BDT B?ro und Datentechnik &KG" => "BDT Büro und Datentechnik & KG",
	"S?tron" => "Sütron",
	"ADD?Nergie" => "ADDÉNergie",
	"Positivo Inform?tica" => "Positivo Informática",
	"W?rth Elektronik eiSos" => "Würth Elektronik eiSos",	
}

output_old = {}
output_new = {}
output_other = {}
File.open("nmap-mac-prefixes.txt") do |file|
	file.each do |line|
		prefix = line[0...6].downcase
		company = line [6..-1].strip
		company = umlautfixes[company] || company
		
		uprefix = prefix.upcase
		output_old["#{uprefix[0..1]}:#{uprefix[2..3]}:#{uprefix[4..5]}"] = company
		
		firstkey = prefix[0..1]
		secondkey = prefix[2..5]
		output_new[firstkey] = {} if output_new[firstkey].nil?
		output_new[firstkey][secondkey] = company
		
		output_other[prefix] = company
	end	
end

def write_file(name, hash) 
	File.open(name + "_pretty.json",'w') do |file|
		file.puts(JSON.pretty_generate(hash))
	end
	File.open(name + ".json",'w') do |file|
		file.puts(JSON.generate(hash))
	end
	
	%x[plutil -convert binary1 #{name}.json -o #{name}.plist]
	%x[gzip -9 #{name}.json -k -f]
end

write_file(old_basename, output_old);
write_file(new_basename, output_new);
write_file(other_basename, output_other);

