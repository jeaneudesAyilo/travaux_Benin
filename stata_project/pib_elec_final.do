/* Projet Stata*/

log using "D:\thème\pib_elec2.smcl", append

*Importation des variables et création de la base*

set more off
import excel "http://api.worldbank.org/v2/en/indicator/NV.AGR.TOTL.KD?downloadformat=excel", firstrow clear
save base1.dta
clear
import excel "http://api.worldbank.org/v2/en/indicator/NV.SRV.TOTL.KD?downloadformat=excel", firstrow
append using base1.dta
save base1.dta,replace
clear
import excel "http://api.worldbank.org/v2/en/indicator/EG.ELC.RNEW.ZS?downloadformat=excel", firstrow
append using base1.dta
save base1.dta,replace
clear
import excel "http://api.worldbank.org/v2/en/indicator/NV.IND.TOTL.ZS?downloadformat=excel", firstrow
append using base1.dta
save base1.dta,replace
clear
import excel "http://api.worldbank.org/v2/en/indicator/NY.GDP.MKTP.KD?downloadformat=excel", firstrow
append using base1.dta
save base1.dta,replace
clear
import excel "http://api.worldbank.org/v2/en/indicator/NV.IND.TOTL.KD?downloadformat=excel", firstrow
append using base1.dta
save base1.dta,replace
clear
import excel "http://api.worldbank.org/v2/en/indicator/SP.URB.TOTL.IN.ZS?downloadformat=excel", firstrow
append using base1.dta
save base1.dta,replace
drop if (DataSource != "Country Name")  &  (DataSource != "Benin")
gen t = _n
drop if (t == 3) |(t == 5 ) | (t == 7) | (t == 9) | (t == 11) | (t == 13)
drop DataSource WorldDevelopmentIndicators
encode C, g(varia)
order C varia
drop C D BK BL
destring E-BJ,replace
xpose, clear varname
rename v1 Annees
rename v2 urban_rate
rename v3 Industry_va
rename v4 GDP_constantUS
rename v5 Industry_va_GDP
rename v6 Renewable_elec_output_percent
rename v7 Services_va
rename v8 Agri_va 
drop _varname
drop if Annees < 1980
save base1.dta,replace

**faute d'avoir le lien de téléchargement de la variable Consommation, nous sommes obligés de le télécharger sous format csv, puis de l'ajouter à la base*
**télécharger grâce lien : https://edenpub.bceao.int/rapport.php* spécifier Bénin, Secteur réel, Comptes nationaux; le fichier téléchargé ce trouve*
*dans notre dossier**
*importer le fichier csv contenu dans le dossier ; remplacer le chemein le chemin d'accès*
clear
import delimited using "C:\Users\ACER\Downloads\exportIndicateurs.csv", delim(";") asdouble
drop if (v1=="BENIN") | (v1=="CODE") | (v1=="LIBELLE")
drop v3
rename v1 Annees
rename v2 Conso_elec
destring Annees , replace
destring Conso_elec, dpcomma replace
merge 1:1 Annees using "base1.dta"
drop _merge

*attribution de label*

label variable GDP_constantUS "GDP in Constant 2010 US$"
label variable Services_va "Services Value added in Constant 2010 US$"
label variable Agri_va "Agriculture Value added in Constant 2010 US$"
label variable Industry_va "Industry Value added in Constant 2010 US$"
label variable Conso_elec "Electric power consumption (kWH)"
label variable urban_rate "urbanization rate (%)"
label variable Industry_va_GDP " Industry value added share in the GDP" 
label variable Renewable_elec_output_percent "Renewable electricity output percentage"

*Création des variables en log*

gen lnGdp = log(GDP_constantUS)
label variable lnGdp "Log of GDP in Constant 2010 US$"
gen lnserv = log(Services_va)
label variable lnserv "Log of Services Value added in Constant 2010 US$"
gen lnagr = log(Agri_va)
label variable lnagr "Log of Agriculture Value added in Constant 2010 US$"
gen lnind = log(Industry_va)
label variable lnind "Log of Industry Value added in Constant 2010 US$"
gen lnconso_elec =log(Conso_elec)
label variable lnconso_elec "log of Electric power consumption (kWH)"

*Statistiques descriptives*

summarize GDP_constantUS Agri_va Industry_va Services_va Conso_elec

tsset Annees ,yearly
**réduction d'échelle pour la représentation graphique**

gen gdp_r = GDP_constantUS/10^9

gen agri_r = Agri_va/10^9
label variable agri_r "Log of Agriculture Value added in Constant 2010 US$ (10^9)"

gen ind_r= Industry_va/10^9
label variable ind_r "Industry Value added in Constant 2010 US$ (10^9)"

gen serv_r = Services_va/10^9
label variable serv_r "Services Value added in Constant 2010 US$ (10^9)"

tsline gdp_r , ymtick(#10, grid tstyle(none)) xmtick(#10, grid tstyle(none)) scheme( s1color ) lwidth(thick) lcolor("0 186 56") tlabel(, format(%ty)) ytitle("GDP in Constant 2010 US$ (10^9)") ttitle("Years") saving(GDP)

tsline Conso_elec, ymtick(#10, grid tstyle(none)) xmtick(#10, grid tstyle(none)) scheme(s1color) lwidth(thick) lcolor(lavender) tlabel(, format(%ty)) ytitle("Consumption (kWH)") ttitle("Years") scale(0.76)  saving(Conso)

tsline ind_r agri_r serv_r , ymtick(#10, grid tstyle(none)) xmtick(#10, grid tstyle(none)) scheme( s1color ) lwidth(thick thick thick thick thick ) lcolor("97 156 255" "248 118 109" dkorange) ttitle("Years") scale(0.67) legend(position(0) bplacement(nwest) cols(1)) clegend(off) saving(Sector) 

tsline urban_rate , ymtick(#10, grid tstyle(none)) xmtick(#10, grid tstyle(none)) scheme( s1color ) lwidth(thick) lcolor(emerald) tlabel(, format(%ty)) ytitle("urbanization rate (%)") ttitle("Years") saving(urban)

graph combine GDP.gph Sector.gph Conso.gph urban.gph
graph export newgr.png, width(2500) height(2100)

**corrélation entre les variables**
pwcorr lnGdp lnagr lnind lnserv lnconso_elec, sig

**test de Dickey Fuller Augmenté : afin de déterminer le nombre de retards à inclure nous représenterons  le corrélogramme partielle des
**séries différenciées .Notons que pour déterminer le nombre de retard optimal, on peut aussi utilser les critères d'informations AIC et BIC:**
**pour un ordre p suffisament élevé on estime différent modèle jusqu'à p=0 et on retient la valeur p qui minimise de Akaike ou Schwarz. le but**
** final est d'avoir des résidus non autocorrélés **

gen d_lnGdp = d.lnGdp
pac d_lnGdp
*nous retenons 0 retard, aucune autocorrélation partielle n'est significative*

gen d_lnagr = d.lnagr
pac d_lnagr
*nous retenons 3 retards, 3ème autocorrélation partielle significative*

gen d_lnind = d.lnind
pac d_lnind
*nous retenons 4 retards*

gen d_lnserv = d.lnserv
pac d_lnserv
*nous retenons 0 retard*

gen d_lnconso= d.lnconso_elec
pac d_lnconso
*nous retenons 0 retard*

**test de stationnarité, la stratégie de test utilisée est celle présentée dans le livre d'économétrie de Bourbonnais (10ème édition).**

/*Dickey Fuller test de lnGdp*/
dfuller lnGdp, trend reg

*à l'ici de ce test on voit que l'hypothèse de non stationnarité ne peut être rejeté a seuil de 5% : la statistique du test est > à la*
*statistique tabulée, mais la tendance n'est pas significative (2.45 < valeur tabulée par Dickey et Fuller :3.18. *
*Donc on  la retire du modèle*

*dfuller lnGdp, drift reg*
*à l'issue de ce test on voit que l'hypothèse de non stationnarité ne peut être rejeté, mais la constante n'est pas significative *
 *-0.33 < valeur tabulée par Dickey et Fuller 2.89 , on  la retire du modèle*

dfuller lnGdp, noconstant 
**d'après ce test on conclut que la série ln_GDP n'est pas stationnaire,elle est I(1) sans dérive, on vérifie que d_lnGdp est stationnaire**
 dfuller d_lnGdp, noconstant

*le test de Phillips-Perron (PP), conduit  au même résultats*
pperron lnGdp, trend reg
pperron lnGdp,  reg
pperron lnGdp, noconstant
pperron d_lnGdp, noconstant

*Augmented Dickey Fuller test de lnagr *

dfuller lnagr, trend lags(3) reg

dfuller lnagr, drift lags(3) reg
*ici l'hypothèse de non stationnarité  peut être rejetée, la constante est significative, donc lnagr serait I(0)*

*test de Phillips-Perron (PP)*
pperron lnagr, trend lags(3) reg

pperron lnagr, lags(3) reg
*ici l'hypothèse de non stationnarité ne peut être rejeté au seuil de 5%, la constante n'est plus significative : *
*0.70 < valeur tabulée par Dickey et Fuller 2.89*

pperron lnagr , noconstant lags(3)
**d'après ce test on conclut que la série lnagr n'est pas stationnaire,elle est I(1) sans dérive, on vérifie que d_lnagr est stationnaire**

pperron d_lnagr

*le test de KPSS va dans le sens de PP*
kpss lnagr, notrend
* ici l'hypothèse nulle de non stationnarité est rejeté car la statistique du test, 1.04 est > à la valeur tabulée 0.463 au seuil de 5%*
*Au final on retient que lnagr est I(1) sans dérive*

*Augmented Dickey Fuller test de lnind, résultat similaire à  lnGdp *
dfuller lnind, lags(4) trend reg
dfuller lnind, lags(4)  reg
dfuller lnind, lags(4)  nocon

**d'après ce test on conclut que la série lnind n'est pas stationnaire,elle est I(1) sans dérive, on vérifie que d_lnind est stationnaire**
dfuller d_lnind, nocon

pperron lnind, lags(4) trend reg
*ce test infirme la présence d'une racine unitaire, et indique plutôt que lnind est stationnaire en tendance, (TS)*

kpss lnind, maxlag(4) 
kpss lnind, maxlag(4) not
*par contre ce test indique plutôt que lnind est I(1)*
*Finallement deux tests vont dans le même sens : DFA, et KPSS; on retient que lnind est I(1)*

*test de stationnarité de lnserv, résultat similaire à ln_GDP*
dfuller lnserv, trend reg
dfuller lnserv, reg
dfuller lnserv, nocon

*on conclut que la série lnserv n'est pas stationnaire,elle est I(1) sans dérive, on vérifie que d_lnserv est stationnaire**
dfuller d_lnserv, nocon

pperron lnserv, trend reg
pperron lnserv,  reg
pperron lnserv,  nocon
pperron d_lnserv,  nocon

*test de stationnarité de lnconso_elec, résultat similaire à ln_GDP*
dfuller lnconso_elec, trend reg
dfuller lnconso_elec, reg
dfuller lnconso_elec, nocon

*on conclut que la série lnconso_elec n'est pas stationnaire,elle est I(1) sans dérive, on vérifie que d_lnConso_elec est stationnaire**
dfuller d_lnconso, nocon

*PP test*
pperron lnconso_elec, trend reg
pperron lnconso_elec,  reg
pperron lnconso_elec,  nocon
pperron d_lnconso,  nocon

*Au total, on retient que toutes les séries sont I(1); toutes les séries sont donc suceptibles d'être cointégrée à la consommation d'élec*

reg lnGdp lnconso_elec
predict resid_GDP, resid
pac d.resid_GDP 
dfuller resid_GDP, drift
*ici la statistique du test est comparée à la valeur tabulée par Engle et Yoo(1987) pour un test de DF simple. Ainsi la statistique du test : -1.697 est*
*supérieure à la valeur tabulée au seuil de 5% : -3.67 . Ainsi il n'y a pas de de relation de long entre la consommation d'electricité*
*et PIB*

reg lnagr lnconso_elec
predict resid_agri, resid
pac d.resid_agri
dfuller resid_agri, drift
*même conclusion comme pour le PIB*

reg lnind lnconso_elec
predict resid_ind, resid
pac d.resid_ind
dfuller resid_ind, drift
*même conclusion comme pour le PIB*


reg d_lnserv lnconso_elec
predict resid_serv, resid
pac d.resid_serv 
dfuller resid_ind, drift lags(4)
/*ici la statistique du test est comparée à la valeur tabulée par Engle et Yoo(1987) pour un test DFA. Ainsi la statistique du test : *
* -1.473 est supérieure à la valeur tabulée au seuil de 5% : -3.29 . Ainsi il n'y a pas de de relation de long entre la consommation d'electricité *
* et la valeur ajoutée des services *

**test de causalité au sens de Granger entre consommation d'électricité et PIB**
*on cherche l'ordre du VAR**/
varsoc d_lnGdp d_lnconso  /**on retient un VAR d'ordre 1 bien que les critères désignent 0*/

set more off
*estimation du modèle VAR(1)*
var d_lnGdp d_lnconso, lags(1) 
varstable, graph modlabel
varlmar
varnorm, jbera

*test de Causalité *
vargranger

**test de causalité au sens de Granger entre consommation d'électricité et la valeur ajouté du secteur secondaire (industrie)**
varsoc d_lnagr d_lnconso
var d_lnagr d_lnconso, lags(1)
**on vérifie la statibilité du modèle VAR, c'est à dire, les inverses des racines sont dans le cercle unitaire** 
varstable, graph modlabel

*on vérifie l'autocorrélation*
varlmar

*normalité des résidus*
varnorm, jbera

*test de causalité de Granger*
vargranger

**test de causalité au sens de Granger entre consommation d'électricité et la valeur ajouté du secteur tertiaire **
varsoc d_lnind  d_lnconso
var  d_lnind d_lnconso , lags(1)
varstable, graph modlabel
varlmar
varnorm, jbera
vargranger
 

**test de causalité au sens de Granger entre consommation d'électricité et la valeur ajouté du secteur tertiaire **
varsoc d_lnserv d_lnconso
var d_lnserv d_lnconso , lags(1)
varstable, graph modlabel
varlmar
varnorm, jbera
vargranger

**Ici, débute la deuxième partie concernant les déterminants de la demande d'electricité**

summarize urban_rate Industry_va_GDP

reg lnconso_elec urban_rate Industry_va_GDP lnGdp Renewable_elec_output_percent
 
*test de multicolinéarité*
 vif
*les statistiques de vif dépassent  10 pour lnGdp et urban_rate, ils sont susceptible d'être à l'origine de multicolinéarité*

reg lnconso_elec urban_rate Industry_va_GDP Renewable_elec_output_percent
vif 
*test d'hétéroscédasticité*
estat archlm, l(1/5)

*test d'autocorrélation*
estat bgodfrey, l(1/5)

*le test indique qu'il y a autocorrélation des résidus*
**correction de l'autocorrélation, par transformation de Cochrane-Orcutt transformation **

*prais lnconso_elec urban_rate Industry_va_GDP Renewable_elec_output_percent, corc

*mais avec cette commande  on obtient l'erreur : convergence not achieved. On peut toutefois corriger l'autocorrélation en incluant** 
*la valeur passée de la variable*

reg lnconso_elec urban_rate Industry_va_GDP Renewable_elec_output_percent l.lnconso_elec

outreg2 using "result.xls"
estat bgodfrey, l(1/5)

save "base1.dta",replace
log close

 


