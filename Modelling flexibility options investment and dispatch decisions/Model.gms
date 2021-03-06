
*===============================================================================
*    Modelling investment and dispatch decisions for flexibility options
*    This model was developed based on the ELTRAMOD model family of the
*        Chair of Energy Economics at TU Dresden
*   Author: Christoph Zöphel
*   Last updated: 25.06.2021
*===============================================================================

*===============================================================================
*                   Scenario Options 
*===============================================================================
$setglobal       FROM    t1
$setglobal       TO      t8760

* Date of Input files 
$setglobal       DATE    200203

* Date of Output files 
$setglobal       DATE1   200831

* Define scenario name
$set PW_SHARE    HP

* Define CO2 price [EUR/t]
$set co2pr       80

* Define model run with (coup=1) or without (coup=0) sector coupling
$set coup        0

* Define flexibility factor (ff) [0,1]
$set ff          0

*if needed: RES expansion scenario name
$set rs          rs80

$if      "%coup%" == "0" $setglobal      NO_SC "";
$if not  "%coup%" == "0" $setglobal      NO_SC "*";


*===============================================================================
*                       File Statements 
*===============================================================================

*Unterdrücken der Listing File
$onUNDF
*$offlisting offsymxref offsymlist
OPTIONS
LIMROW = 0
LIMCOL = 0
SOLPRINT = OFF
Profile=1
reslim = 1E9
;

*===============================================================================
*                       Data Input 
*===============================================================================

set
c                        list of countries
tech                     list of technologies
p                        list of power plants
f                        list of fuels
dsm                      list of DSM processes
ptx                      list of Power-to-X (PtX) technologies
li                       list of lines (connection between two countries)

s(tech)                  Subset for electricity storage technologies
nops(tech)               Subset for storages not PSP
pp(tech)                 Subset for dispatchable power plants without storages
ramp(tech)               Subset for power plants with ramping constraints
chp(tech)                Subset for CHP plants
flex(tech)               Subset for dispatchable RES technologies
flex_max                 Set of maximum potential for dispatchable RES technologies
s_csp(tech)              Subset for CSP technology
s_bio(tech)              Subset for biomass power plants
s_geo(tech)              Subset for geothermal power plants
shi_dsm(dsm)             Subset of DSM shifting processes
she_dsm(dsm)             Subset of DSM load shedding processes

ch_p                     list of power plant characteristics
ch_c                     list of country specific characteristics
ch_tech                  list of technology characteristics
ch_flex                  list of technology characteristics for dispatchable RES technologies
ch_dsm                   list of DSM process characteristics
ch_ptx                   list of PtX technology characteristics

map_ptech(p,tech)        map plant to technology
map_pc(p,c)              map plant to country
map_techf(tech,f)        map technology to fuel
map_pf(p,f)              map plant to fuel
map_flexc(flex_max,c)    map dispatchable RES technology potentials to country
map_flexf(flex_max,f)    map dispatchable RES technology potentials to fuel
map_flextech(flex_max,tech) map dispatchable RES technology potentials to technology
map_dsmc(dsm,c)          map DSM process to country



t /%FROM%*%TO%/
t_d(t)

;

alias (c, cc);
alias (t,tt);

scalar
i                        interest rate                                                   /0.08/

i_ntc                    interest rate for NTC investments                               /0.07/
lt_ntc                   economical lifetime of NTC                                      /40/
;

parameters
*=========prices==========================
pr_f(t,f)                fuel price  [€ per MWhth] and CO2 price [€ per tCO2]

*=========prices/costs ==========================
co_curt                  Cost for curtailment of renewables [€ per MWh]
co_f(tech,t)             cost for fuel (fuel price + mark up + transport costs) in € per MWhth
co_co2(p,t)              cost for CO2 (CO2-allowances * emission factor) in € per MWhth

*=========load =================
char_c(c,ch_c)           countrie specific characteristics
dem(t,c)                 load [MW]
res_dem(t,c)             residual load [MW]
dem_heat(t,c)            heat demand  [% of peak heat demand (see country characteristics)]
cf_ev                    EV charging demand [% of yearly energy demand of EV fleet based on driving distance]
cf_ev_p                  EV charging power availablility [% of battery capacity of EV fleet]

*========technology characteristics=====================
char_p(p,ch_p)           all characteristics of a plant
char_tech(tech,ch_tech)  all characteristics of a technology
char_flex(flex_max,ch_flex) all characteristics of dispatchable RES technology
char_dsm(dsm,ch_dsm)     all characteristics of DSM processes
char_ptx(ptx,ch_ptx)     all characteristics of a PtX technology

*========NTC & load flows =============================
li_c(li,c,cc)            dedicates a line to the respective countries
li_ntc                   NTC value of a line
ntc(c,cc)                Net transfer capacity between country A and country B [MW]

*======= costs =======================================
co_ntc                   costs for NTC expansion
co_up(tech,t)            cost for ramping up (fuel related + depreciation)
co_down(tech,t)          cost for ramping down (fuel related)
anf(tech)                annuity factor for a technology
an(tech)                 annuity of a technology
anf_ntc                  annuity factor for NTC expansion
an_ntc                   annuity of NTC expanion
anf_dsm                  annuity factor for a DSM process
an_dsm(dsm)              annuity of DSM process
an_ptx(ptx)              annuity of PtX technology
anf_ptx(ptx)             annuity factor for a PtX technology
anf_estor(ptx)           annuity factor for an energy storage power capacity
an_estor(ptx)            annuity of energy storage
anf_stocap(tech)         annuity factor for electricity storage power
an_stocap(tech)          annuity of electricity storage power
anf_flex                 annuity factor for dispatchable RES technology
an_flex                  annuity of dispatchable RES technology

pth_co                   costs of PtH dispatch
ptg_co                   costs of PtG dispatch
gb_co                    costs of gas boiler dispatch
ev_co                    costs of EV charging
sr_co                    costs of steam reforming
ice_co                   costs of ICE driving

*====== load shifting ==============================
red_avail(t,dsm)         times series of DSM reduction availability
inc_avail(t,dsm)         times series of DSM increase availability
dsm_avail(t,dsm)         times series of overall DSM availability
;

*===============================================================================
*                Data load
*===============================================================================

$onecho >temp1.tmp
set=c                    rng=country!A4          Rdim=1  cdim=0
set=ch_w                 rng=Mapping1!A2         Rdim=0  Cdim=1
par=char_w               rng=Mapping1!A2         Rdim=1  Cdim=1
Par=res_dem              rng=Residual_Load!B2    Rdim=1  Cdim=1
Par=dem_heat             rng=Heat!B1             Rdim=1  Cdim=1
Par=solar                rng=solar!B1            Rdim=1  Cdim=1
Par=cf_ev                rng=EV!B1               Rdim=1  Cdim=1
Par=cf_ev_p              rng=EV_power!B1         Rdim=1  Cdim=1
$offecho

$onUNDF
$IF NOT EXIST %DATE%_TS_%PW_SHARE%_%rs%.gdx $call "gdxxrw data\%DATE%_TS_%PW_SHARE%_%rs%.xlsx SQ=N SE=10 cmerge=1 @temp1.tmp"
$gdxin %DATE%_TS_%PW_SHARE%_%rs%.gdx
$load c ch_w
$load char_w res_dem dem_heat solar cf_ev cf_ev_p
$gdxin
$offUNDF

$onecho >temp2.tmp
set=p                    rng=Plants!A4           rdim=1  cdim=0
set=tech                 rng=technologies!A4     rdim=1  cdim=0
set=ch_p                 rng=Plants!A3           rdim=0  Cdim=1
set=c                    rng=countries!A4        Rdim=1  cdim=0
set=ch_c                 rng=countries!A3        rdim=0  Cdim=1
set=f                    rng=Fuels!A1            Rdim=0  cdim=1
set=ch_tech              rng=technologies!A3     rdim=0  Cdim=1
set=ptx                  rng=PtX!A4              rdim=1  cdim=0
set=ch_ptx               rng=PtX!A3              rdim=0  Cdim=1
set=map_techf            rng=Technologies!AC3    Rdim=2  cdim=0
set=map_pc               rng=Plants!V3           Rdim=2  cdim=0
set=map_ptech            rng=Plants!U3           Rdim=2  cdim=0
set=map_pf               rng=Plants!W3           Rdim=2  cdim=0
Par=pr_f                 rng=Fuels!A1            Rdim=1  cdim=1
Par=char_p               rng=Plants!A3           Rdim=1  cdim=1
Par=char_c               rng=countries!A3        Rdim=1  cdim=1
Par=char_tech            rng=Technologies!A3     Rdim=1  cdim=1
Par=char_ptx             rng=PtX!A3              rdim=1  Cdim=1
$offecho

$onUNDF
$IF NOT EXIST %DATE%_Tech_data.gdx $call "gdxxrw data\%DATE%_Tech_data.xlsm SQ=N SE=10 cmerge=1 @temp2.tmp"
$gdxin %DATE%_Tech_data.gdx
$load p tech ch_p ch_c ch_tech f map_techf map_pc map_ptech map_pf ptx ch_ptx
$load pr_f  char_p char_c char_tech char_ptx
$gdxin
$offUNDF

$onecho >temp3.tmp
set=li                   rng=line!B4             RDim=1  cdim=0
Par=li_c                 rng=line!B3             RDim=2  CDim=1
Par=co_ntc               rng=cost_ntc!B2         RDim=1  CDim=1
par=li_ntc               rng=ntc!A4              RDim=2  CDim=0
$offecho

$onUNDF
$IF NOT EXIST %DATE%_NTC.gdx $call "gdxxrw data\%DATE%_NTC.xlsx SQ=N SE=10 cmerge=1 @temp3.tmp"
$gdxin %DATE%_NTC.gdx
$load  li li_c co_ntc li_ntc
$gdxin
$offUNDF


$onecho >temp4.tmp
set=dsm                  rng=MOD_DSM_Input!A4            rdim=1  cdim=0
set=ch_dsm               rng=MOD_DSM_Input!A3            rdim=0  Cdim=1
set=map_dsmc             rng=MOD_DSM_Input!P3            Rdim=2  cdim=0
par=char_dsm             rng=MOD_DSM_Input!A3            rdim=1  Cdim=1
par=red_avail            rng=MOD_DSM_red!A1              rdim=1  Cdim=1
par=dsm_avail            rng=DSM_avail!A1                rdim=1  Cdim=1
$offecho

$onUNDF
$IF NOT EXIST %DATE%_DSM.gdx $call "gdxxrw data\%DATE%_DSM.xlsx SQ=N SE=10 cmerge=1 @temp4.tmp"
$gdxin %DATE%_DSM.gdx
$load  dsm ch_dsm map_dsmc
$load  char_dsm red_avail dsm_avail
$gdxin
$offUNDF

$onecho >temp5.tmp
set=flex_max             rng=flexRES!A4          rdim=1  cdim=0
set=ch_flex              rng=flexRES!A3          rdim=0  Cdim=1
Par=char_flex            rng=flexRES!A3          Rdim=1  cdim=1
set=map_flexc            rng=flexRES!K3          Rdim=2  cdim=0
set=map_flextech         rng=flexRES!O3          Rdim=2  cdim=0
set=map_flexf            rng=flexRES!M3          Rdim=2  cdim=0
$offecho

$onUNDF
$IF NOT EXIST %DATE%_dRES.gdx $call "gdxxrw data\%DATE%_dRES.xlsx SQ=N SE=10 cmerge=1 @temp5.tmp"
$gdxin %DATE%_dRES.gdx
$load flex_max ch_flex map_flexc map_flextech map_flexf
$load char_flex
$gdxin
$offUNDF

scalar
t_opt    optimisation period;
t_opt = card(t);

parameter
h        Hilfsparameter;
h(t) = ord(t);


*========= calaculation of needed parameters ==========
*conventional power plants
co_f(tech,t)=    sum(f,pr_f(t,f)$map_techf(tech,f));

*Load change costs
co_up(tech,t)=   (co_f(tech,t)+%co2pr%*char_tech(tech,'co2'))*char_tech(tech,'co_rf') + char_tech(tech,'co_rcd');
co_down(tech,t)= char_tech(tech,'co_rcd');

*Gas-price as reference divided by efficiency reference process multiplied by efficiency ptx process
ice_co(c)=       (ice_inv*((1+i)**ice_lt*i)/((1+i)**ice_lt-1))/char_c(c,'km_car') + ice_f + (ice_eff_co2*10E-6*%co2pr%);
gb_co=           (gb_inv*((1+i)**gb_lt*i)/((1+i)**gb_lt-1))/gb_h + (33.7+co2fac*%co2pr%*0.2)/gb_eff;
sr_co=           (sr_inv*((1+i)**sr_lt*i)/((1+i)**sr_lt-1))/sr_h + (33.7+co2fac*%co2pr%*0.285)/sr_eff;

*lines
ntc(c,cc)=       sum(li,(li_ntc(c,cc)*li_c(li,c,cc)));

*annuities
anf(tech)=       ((1+i)**char_tech(tech,'tl')*i)/((1+i)**char_tech(tech,'tl')-1);
an(tech)=        char_tech(tech,'co_inv')*anf(tech);
anf_ntc=         ((1+i_ntc)**lt_ntc*i_ntc)/((1+i_ntc)**lt_ntc-1 );
an_ntc(c,cc)=    anf_ntc*co_ntc(c,cc);
anf_dsm=         ((1+i)**20*i)/((1+i)**20-1);
an_dsm(dsm)=     char_dsm(dsm,'c_inv')*anf_dsm;

anf_ptx(ptx)=    ((1+i)**char_ptx(ptx,'lt_ptx')*i)/((1+i)**char_ptx(ptx,'lt_ptx')-1);
an_ptx(ptx)=     char_ptx(ptx,'co_ptx')*anf_ptx(ptx);
anf_estor(ptx)=  ((1+i)**char_ptx(ptx,'lt_ptx_stor')*i)/((1+i)**char_ptx(ptx,'lt_ptx_stor')-1);
an_estor(ptx)=   char_ptx(ptx,'co_ptx_stor')*anf_ptx(ptx);

anf_estor('ev')= 0;
an_estor('ev')=  0;

*============= new sets========================================================

ramp(tech)$ (char_tech(tech,'co_rf') > 0) =      YES;
flex(tech)$ (char_tech(tech,'flex_res') = 1) =   YES;
s_csp(tech)$ (char_tech(tech,'csp_y') = 1) =     YES;
s_bio(tech)$ (char_tech(tech,'bio_y') = 1) =     YES;
s_geo(tech)$ (char_tech(tech,'geo_y') = 1) =     YES;
shi_dsm(dsm)$ (char_dsm(dsm,'shed_y') = 0) =     YES;
she_dsm(dsm)$ (char_dsm(dsm,'shed_y') = 1) =     YES;
s(tech)$ (char_tech(tech,'stor') eq 1) =         YES;
nops(tech)$ (char_tech(tech,'no_psp') eq 1) =    YES;
pp(tech)$ (char_tech(tech,'stor') eq 0) =        YES;
chp(tech)$(char_tech(tech,'chp') eq 1)=          YES;
t_d(t)$ (MOD(ord(t)-1,24)=0 ) =                  YES;



*===============================================================================
*                         Model formulation
*===============================================================================


*========= Variable declaration ================================================


Variables
TOTAL_COSTS                      total costs [€]
;

positive variables
COSTS(c)                         country-specific costs
DC(c,t)                          Dispatch costs
IC(c)                            Investment costs

G_P(tech,c,t)                    Dipatch of a power plant  [MW]
G_P_INV(tech,c)                  Generation technology investments
LC_UP(tech,c,t)                  load change up
LC_DOWN(tech,c,t)                load change down
CO_LC_up(tech,c,t)               costs load change up
CO_LC_down(tech,c,t)             costs load change down

CHARGE(tech,c,t)                 Charging of Storages [MW]
SL(tech,c,t)                     Electricity storage level [MW]
STO_inv(tech,c)                  Electricity storage charging power
EXPORT(t,c,cc)                   Export from one country A to B (export from A to B corresponds to import in B from A)
NTC_INV(c,cc)                    NTC capacity expansion [MW]

PTX_gen(ptx,c,t)                 PtX electrification
PTX_gen_s(ptx,c,t)               PtX electrification for energy storages
PTX_gen_d(ptx,c,t)               PtX electrification for direct supply
PTX_inv(ptx,c)                   Investments in PtX technologies
PTX_stor_out(ptx,c,t)            Energy storage discharging
PTX_stor_in(ptx,c,t)             Energy storage charging
PTX_SL(ptx,c,t)                  Energy storage level
PTX_stor_cap(ptx,c,t)            Energy storage capacity
PTX_stor_inv(ptx,c)              Energy storage investments
CHP_s(tech,c,t)                  CHP dispatch for heat storages
CHP_d(tech,c,t)                  CHP dispatch for direct heat provision

G_BOIL                           Dispatch of gas boiler
SR(c,t)                          Dispatch steam reforming
ICE(c)                           Dispatch of ICE

RED_DEM(dsm,t)                   DSM reduction of demand
INC_DEM(dsm,t)                   DSM increase of demand
DSM_RED(dsm,t,tt)                DSM reduction of demand on hold
DSM_INC(dsm,t)                   DSM increase of demand on hold
DSM_SHE(dsm,t)                   DSM load shedding
DSM_INV(dsm)                     DSM investment
DSM_VAR(dsm,t)                   DSM dispatch costs

CSP(tech,c,t)                    CSP dispatch
CSP_HS_out(tech,c,t)             CSP heat storage discharging
CSP_HS_in(tech,c,t)              CSP heat storage charging
SL_csp(tech,c,t)                 CSP heat storage level
hVOL_csp(tech,c,t)               CSP heat storage capacity
hVOL_csp_inv(tech,c)             CSP heat storage investment

EV_LOAD(c,t)                     EV charging demand

CURT_RES(c,t)                    Curtailment of RES in a country [MW]
;


*========= Equation declaration ================================================

Equations
target_function                  Target function
energy_balance                   Energy balance
costs_country                    Country-specific cost definition
LC_cost1                         Power plant ramping up restriction
LC_cost2                         Power plant ramping down restriction
IC_cost                          Investment cost definition
DC_cost                          Dispatch cost definition
DSM_cvar                         Variable DSM cost definition
GEN_c1                           Power plant generation restriction
GEN_C2                           Reservoir plant full load hour restriction
GEN_C3                           Ramping constraint
CSP_c1                           CSP dispatch restriction
CSP_c2                           CSP energy balance
CSP_c3                           CSP storage equation
CSP_c4                           CSP storage level restriction
RES_c1                           Biomass generation potential restriction
STOR_c1                          Electricity storage equation first time step
STOR_c11                         Electricity storage equation
STOR_c2                          Electricity storage level restriction
STOR_c3                          Electricity storage charging constraint
STOR_c4                          Electricity storage discharging constraint
NTC_c1                           NTC export restriction
NTC_c2                           NTC import equals export capacity equation
DSM_c1                           DSM increase and reduction balance over time
DSM_c2                           DSM restriction
DSM_c3                           DSM increase energy amount assignment on hold
DSM_c4                           DSM reduction energy amount assignment on hold
DSM_c5                           DSM availability profile equation
SHE_c1                           Load shedding availability profile equation
SHE_c2                           Load shedding restriction
PTX_c1                           PtX dispatch restriction
PTH_c11                          CHP heat flow assignment
PTH_c12                          PtH heat flow assignment
PTH_c13                          PtH direct heat supply assignment
PTH_c2                           Equation for minimum share of electricity for heat
PTH_c3                           Heat balance
PTH_c4                           Heat storage equation for first time step
PTH_c44                          Heat storage equation
PTH_c5                           Heat storage level restriction
PTH_c6                           Heat storage level equal in first and last time step
PTH_c7                           Heat storage discharging constraint
PTG_c12                          PtG Hydrogen flow equation
PTG_c13                          PtG Direct hydrogen supply assignment
PTG_c2                           Equation for minimum share of electricity for hydrogen
PTG_c3                           Hydrogen balance equation
PTG_c4                           Hydrogen storage equation for first time step
PTG_c44                          Hydrogen storage equation
PTG_c5                           Hydrogen storage level restriction
PTG_c6                           Hydrogen storage level equal in first and last time step
PTG_c7                           Hydrogen storage discharging restriction
EV_c1                            EV hourly charging demand assignment
EV_c3                            EV storage equation for first time step
EV_c33                           EV storage equation
EV_c5                            EV storage level restriction
EV_c6                            EV storage charging restriction
EV_c7                            EV storage discharging restriction
EV_c8                            EV storage level equal in first and last time step
EV_c9                            EV driving distance balance
;

*==========target function====================

target_function..
TOTAL_COSTS =e=
                 sum((c),costs(c))
                 ;

costs_country(c)..
costs(c) =e=
                 IC(c)*card(t)/8760
                 + sum(t, DC(c,t))
                 + sum((tech,t), CO_LC_UP(tech,c,t)
                                 + CO_LC_DOWN(tech,c,t))
                 + sum(tech, G_P_INV(tech,c)*char_tech(tech,'co_f'))*card(t)/8760
                 + sum((ptx),PTX_inv(ptx,c)*char_ptx(ptx,'co_f_ptx'))*card(t)/8760
                 + sum((dsm,t)$(map_dsmc(dsm,c)), DSM_VAR(dsm,t))
                 + sum(t, G_BOIL(c,t)*gb_co)
                 + sum(t, SR(c,t)*sr_co)
                 + ICE(c)*ICE_co(c)
                 ;

*=========Energy balance=====================

energy_balance(c,t)..
                 sum(tech, G_P(tech,c,t))
                 + sum(shi_dsm$map_dsmc(shi_dsm,c), RED_DEM(shi_dsm,t))
                 + sum(she_dsm$map_dsmc(she_dsm,c), DSM_SHE(she_dsm,t))
         =e=
                 res_dem(t,c)
                 +(sum(cc,EXPORT(t,c,cc))-sum(cc,export(t,cc,c)))
                 + CURT_RES(c,t)
                 + sum(s, CHARGE(s,c,t))
                 + sum(shi_dsm$map_dsmc(shi_dsm,c), INC_DEM(shi_dsm,t))
%NO_SC%$ontext
                 + PTX_gen('pth',c,t)
                 + PTX_gen('ptg',c,t)
                 + PTX_stor_in('ev',c,t)
                 + (1-%ff%)*EV_LOAD(c,t)
                 - PTX_stor_out('ev',c,t)
$ontext
$offtext
                 ;

*========= further cost equations==================================
LC_cost1(ramp,c,t)..
CO_LC_UP(ramp,c,t) =e=
                 LC_UP(ramp,c,t)*co_up(ramp,t);
LC_cost2(ramp,c,t)..
CO_LC_DOWN(ramp,c,t) =e=
                 LC_DOWN(ramp,c,t)*co_down(ramp,t);

IC_cost(c)..
IC(c) =e=
                 sum(tech$(char_tech(tech,'stor') eq 0),G_P_INV(tech,c)*an(tech))
                 + sum(s,G_P_INV(s,c)*an(s)*0.8)
                 + sum(dsm$map_dsmc(dsm,c), DSM_INV(dsm)*an_dsm(dsm))
                 + 0.5 * sum((cc), NTC_INV(c,cc)*an_ntc(c,cc))
                 + sum(tech, hVOL_csp_inv(tech,c)*an_ptx('pth'))
                 + sum((ptx),PTX_inv(ptx,c)*an_ptx(ptx))
                 + sum((ptx),PTX_stor_inv(ptx,c)*an_estor(ptx))
                 ;


DC_cost(c,t)..
DC(c,t) =e=
                 sum(pp,G_P(pp,c,t)*char_tech(pp,'co_v')) +
                 0.5*sum(s,(G_P(s,c,t) + CHARGE(s,c,t))*char_tech(s,'co_v'))
                 + sum(tech,G_P(tech,c,t)*((co_f(tech,t)+co2fac*%co2pr%*char_tech(tech,'co2'))/char_tech(tech,'eta_p')))
                 ;
DSM_cvar(dsm,t)..
DSM_VAR(dsm,t) =e=
                 RED_DEM(dsm,t)*char_dsm(dsm,'c_var')
                 + INC_DEM(dsm,t)*char_dsm(dsm,'c_var')
                 + DSM_SHE(dsm,t)*char_dsm(dsm,'c_var')
                 ;

*======== Technical constraints power plants =========

CURT_RES.fx(c,t)$(res_dem(t,c)>0)=0;
CURT_RES.up(c,t)$(res_dem(t,c)<0)=res_dem(t,c)*(-1);

GEN_c1(tech,c,t)..
G_P(tech,c,t) =l=
                 G_P_INV(tech,c);

G_P_INV.up('Nuclear',c)=                                                                                         sum(p$(map_ptech(p,'Nuclear')),char_p(p,'p_inst')$map_pc(p,c));
G_P_INV.fx('Lignite',c)$sum(p$(map_ptech(p,'Lignite') and map_pc(p,c)),char_p(p,'p_add')=0)=                     0;
G_P_INV.fx('Coal',c)$sum(p$(map_ptech(p,'Coal') and map_pc(p,c)),char_p(p,'p_add')=0)=                           0;
G_P_INV.fx('Lignite_chp',c)$sum(p$(map_ptech(p,'Lignite_chp') and map_pc(p,c)),char_p(p,'p_add')=0)=             0;
G_P_INV.fx('Coal_chp',c)$sum(p$(map_ptech(p,'Coal_chp') and map_pc(p,c)),char_p(p,'p_add')=0)=                   0;
G_P_INV.fx('PSP',c)=                                                                                             sum(p$(map_ptech(p,'PSP')),char_p(p,'p_inst')$map_pc(p,c));
G_P_INV.fx('Reservoir',c)=                                                                                       sum(p$(map_ptech(p,'Reservoir')),char_p(p,'p_inst')$map_pc(p,c));
G_P_INV.fx('RoR',c)=                                                                                             sum(p$(map_ptech(p,'RoR')),char_p(p,'p_inst')$map_pc(p,c));
SL.up('PSP',c,t)=                                                                                                sum(p$(map_ptech(p,'PSP')),char_p(p,'p_stor')$map_pc(p,c));
SL.fx('PSP',c,'t1')=                                                                                             0.5*sum(p$(map_ptech(p,'PSP')),char_p(p,'p_stor')$map_pc(p,c));
SL.fx('PSP',c,t)$(ord(t)=t_opt)=                                                                                 0.5*sum(p$(map_ptech(p,'PSP')),char_p(p,'p_stor')$map_pc(p,c));

GEN_C2('reservoir',c)..
sum(t,G_P('reservoir',c,t)) =l=
                 sum(p$(map_ptech(p,'reservoir') and map_pc(p,c)),char_p(p,'P_inst')*char_p(p,'Vlh_Max'));

GEN_C3(ramp,c,t)..
LC_UP(ramp,c,t)- LC_DOWN(ramp,c,t) =e=
                 G_P(ramp,c,t+1)-G_P(ramp,c,t);

* ====== Dispatchable RES ======================================================

*====== CSP
CSP_c1(s_csp,c,t)$(sum(flex_max$(map_flexc(flex_max,c) and map_flextech(flex_max,s_csp)),char_flex(flex_max,'p_add'))>0)..
CSP(s_csp,c,t) =e=
                 G_P_INV(s_csp,c)*solar(t,c);

CSP_c2(s_csp,c,t)$(sum(flex_max$(map_flexc(flex_max,c) and map_flextech(flex_max,s_csp)),char_flex(flex_max,'p_add'))>0)..
CSP(s_csp,c,t) + CSP_HS_out(s_csp,c,t) =e=
                 G_P(s_csp,c,t)/char_tech(s_csp,'eta_p') + CSP_HS_in(s_csp,c,t);

CSP_c3(s_csp,c,t)$(sum(flex_max$(map_flexc(flex_max,c) and map_flextech(flex_max,s_csp)),char_flex(flex_max,'p_add'))>0)..
SL_csp(s_csp,c,t) =e=
                 char_ptx('pth','eff_ptx_stor') * SL_csp(s_csp,c,t-1) +  CSP_HS_in(s_csp,c,t)-CSP_HS_out(s_csp,c,t);

CSP_c4(s_csp,c,t)$(sum(flex_max$(map_flexc(flex_max,c) and map_flextech(flex_max,s_csp)),char_flex(flex_max,'p_add'))>0)..
SL_csp(s_csp,c,t) =l= hVOL_csp_inv(s_csp,c);

G_P_INV.up(s_csp,c) = sum(flex_max$(map_flexc(flex_max,c) and map_flextech(flex_max,s_csp)),char_flex(flex_max,'p_add'));

*====== biomass
RES_c1(s_bio,c)..
sum(t, G_P(s_bio,c,t)) =l=
                 sum(flex_max$(map_flexc(flex_max,c) and map_flextech(flex_max,s_bio)),char_flex(flex_max,'g_add'))*1000000;
*====== geo
G_P_INV.up(s_geo,c) = sum(flex_max$(map_flexc(flex_max,c) and map_flextech(flex_max,s_geo)),char_flex(flex_max,'p_add'));

*======== Storages ========================================
STOR_c1(nops,c,t)$(ord(t)=1)..
SL(nops,c,t) =e=
                 0.5*G_P_INV(nops,c)*char_tech(nops,'ep_ratio')
                 + CHARGE(nops,c,t)*char_tech(nops,'eta_char')
                 - G_P(nops,c,t)/char_tech(nops,'eta_p');

STOR_c11(s,c,t)$(ord(t)>1)..
SL(s,c,t) =e=
                 SL(s,c,t-1)
                 + CHARGE(s,c,t)*char_tech(s,'eta_char')
                 - G_P(s,c,t)/char_tech(s,'eta_p');

STOR_c2(nops,c,t)..
SL(nops,c,t) =l=
                 G_P_INV(nops,c)*char_tech(nops,'ep_ratio')
;

STOR_c3(s,c,t)..
CHARGE(s,c,t) =l=
                 G_P_INV(s,c);

STOR_c4(nops,c,t)$(ord(t)=card(t))..
SL(nops,c,t) =e=
                 0.5*G_P_INV(nops,c)*char_tech(nops,'ep_ratio')

;


*======== NTC and load flows ===============

NTC_c1(t,c,cc)$(ntc(c,cc)>0)..
Export(t,c,cc) =l=
                 ntc(c,cc)
                 + NTC_INV(c,cc)
                 ;

NTC_c2(c,cc)..
NTC_INV(c,cc) =e=
                NTC_INV(cc,c)
                 ;

Export.fx(t,c,cc)$(ntc(cc,c)=0) =0;

*======= DSM =========================
*====== Shifting
DSM_c1(shi_dsm,t)..
DSM_INC(shi_dsm,t) =e=
                 sum(tt$(ord(tt)>=ord(t)-char_dsm(shi_dsm,'t_shift') AND ord(tt)<=ord(t)+char_dsm(shi_dsm,'t_shift')),DSM_RED(shi_dsm,t,tt));

DSM_c2(shi_dsm,t)..
INC_DEM(shi_dsm,t) + RED_DEM(shi_dsm,t) =l=
                 DSM_INV(shi_dsm)*dsm_avail(t,shi_dsm);

DSM_c3(shi_dsm,t)..
DSM_INC(shi_dsm,t) =e=
                 INC_DEM(shi_dsm,t);

DSM_c4(shi_dsm,t)..
sum(tt$(ord(tt)>=ord(t)-char_dsm(shi_dsm,'t_shift') AND ord(tt)<=ord(t)+char_dsm(shi_dsm,'t_shift')),DSM_RED(shi_dsm,tt,t)) =e=
                 RED_DEM(shi_dsm,t);

DSM_c5(shi_dsm,t)..
sum(tt$(ord(tt)>=ord(t) AND ord(tt)<ord(t)+char_dsm(shi_dsm,'t_dayLim') ) , DSM_INC(shi_dsm,tt)) =l=
                 DSM_INV(shi_dsm)*char_dsm(shi_dsm,'t_shift');

*====== Shedding
SHE_c1(she_dsm,t)..
sum(tt$(ord(tt)>=ord(t) AND ord(tt)<ord(t)+char_dsm(she_dsm,'t_dayLim') ) , DSM_SHE(she_dsm,tt)) =l=
                 DSM_INV(she_dsm)*char_dsm(she_dsm,'t_shift');

DSM_SHE.fx(she_dsm,t)$(ord(t)=1)=0;

SHE_c2(she_dsm,t)..
DSM_SHE(she_dsm,t) =l=
                 DSM_INV(she_dsm)* red_avail(t,she_dsm);

DSM_INV.up(shi_dsm)=char_dsm(shi_dsm,'DSM_max');
DSM_INV.up(she_dsm)=char_dsm(she_dsm,'DSM_max');

*===================== ALL PtX =================================================
PTX_c1(ptx,c,t)..
PTX_gen(ptx,c,t) =l= PTX_inv(ptx,c);

PTX_gen.fx(ptx,c,t)$(%coup%=0)           =0;
PTX_inv.fx(ptx,c)$(%coup%=0)             =0;
PTX_stor_out.fx('ptg',c,t)$(%coup%=0)    =0;
PTX_stor_out.fx('ev',c,t)$(%coup%=0)     =0;
PTX_stor_in.fx(ptx,c,t)$(%coup%=0)       =0;
PTX_stor_inv.fx('ptg',c)$(%coup%=0)      =0;
PTX_stor_inv.fx('ev',c)$(%coup%=0)       =0;

*======================power to heat ===========================================

PTX_gen_s.fx('pth',c,t)$(%ff%=0)         =0;

PTH_c11(chp,c,t)..
G_P(chp,c,t) =e= (CHP_s(chp,c,t) + CHP_d(chp,c,t))*0.7;

PTH_c12(c,t)..
PTX_gen('pth',c,t) =e= (PTX_gen_s('pth',c,t)+PTX_gen_d('pth',c,t))/char_ptx('pth','eff_ptx');
;

PTH_c13(c,t)..
PTX_gen_d('pth',c,t)/char_ptx('pth','eff_ptx') =g= (1-%ff%)*PTX_gen('pth',c,t)
;

PTH_c2(c)..
sum(t,PTX_gen('pth',c,t)*char_ptx('pth','eff_ptx')) =g= 0.5 * sum(t,dem_heat(t,c)*char_c(c,'p_heat'));


PTH_c3(c,t)..
                 PTX_gen_d('pth',c,t)
                 + sum(chp, CHP_d(chp,c,t))
                 + PTX_stor_out('pth',c,t)
                 + G_BOIL(c,t)
         =e=
                 dem_heat(t,c)*char_c(c,'p_heat');

PTH_c4(c,t)$(ord(t)=1)..
PTX_SL('pth',c,t) =e=
                 0.5*PTX_stor_inv('pth',c)
                 + PTX_gen_s('pth',c,t)
                 + sum(chp, CHP_s(chp,c,t))
                 - PTX_stor_out('pth',c,t);

PTH_c44(c,t)$(ord(t)>1)..
PTX_SL('pth',c,t) =e=
                 PTX_SL('pth',c,t-1)*char_ptx('pth','eff_ptx_stor')
                 + PTX_gen_s('pth',c,t)
                 + sum(chp, CHP_s(chp,c,t))
                 - PTX_stor_out('pth',c,t);

PTH_c5(c,t)..
PTX_SL('pth',c,t) =l= PTX_stor_inv('pth',c);

PTH_c6(c,t)$(ord(t)=card(t))..
PTX_SL('pth',c,t) =e= 0.5*PTX_stor_inv('pth',c);

PTH_c7(c,t)..
PTX_stor_out('pth',c,t) =l=
                 PTX_inv('pth',c)*char_ptx('pth','eff_ptx');

*====== PTG ====================================================================
PTX_gen_s.fx('ptg',c,t)$(%ff%=0)         =0;
PTX_stor_out.fx('ptg',c,t)$(%ff%=0)      =0;
PTX_stor_inv.fx('ptg',c)$(%ff%=0)        =0;

PTG_c12(c,t)..
PTX_gen('ptg',c,t) =e= (PTX_gen_s('ptg',c,t)+PTX_gen_d('ptg',c,t))/char_ptx('ptg','eff_ptx');
;

PTG_c13(c,t)..
PTX_gen_d('ptg',c,t)/char_ptx('ptg','eff_ptx') =g= (1-%ff%)*PTX_gen('ptg',c,t)
;

PTX_gen_d.up('ptg',c,t)$(%ff%=0)=char_c(c,'h2_demand')/card(t)/char_ptx('ptg','eff_ptx')*0.5/0.9;

PTG_c2(c)..
sum(t, PTX_gen('ptg',c,t)*char_ptx('ptg','eff_ptx')) =g= 0.5*char_c(c,'h2_demand');

PTG_c3(c,t)..
                 PTX_gen_d('ptg',c,t)
                 + PTX_stor_out('ptg',c,t)
                 + SR(c,t)
         =e=
                 char_c(c,'h2_demand')/card(t);

PTG_c4(c,t)$(ord(t)=1)..
PTX_SL('ptg',c,t) =e=
                 0.5*PTX_stor_inv('ptg',c)
                 + PTX_gen_s('ptg',c,t)
                 - PTX_stor_out('ptg',c,t);

PTG_c44(c,t)$(ord(t)>1)..
PTX_SL('ptg',c,t) =e=
                 PTX_SL('ptg',c,t-1)*char_ptx('ptg','eff_ptx_stor')
                 + PTX_gen_s('ptg',c,t)
                 - PTX_stor_out('ptg',c,t);

PTG_c5(c,t)..
PTX_SL('ptg',c,t) =l= PTX_stor_inv('ptg',c);

PTG_c6(c,t)$(ord(t)=card(t))..
PTX_SL('ptg',c,t) =e= 0.5*PTX_stor_inv('ptg',c);


PTG_c7(c,t)..
PTX_stor_out('ptg',c,t) =l=
                 PTX_inv('ptg',c)*char_ptx('ptg','eff_ptx');

*====== EV ======================================================================

PTX_gen.fx('ev',c,t)=0;
PTX_gen_s.fx('ev',c,t)=0;
PTX_gen_d.fx('ev',c,t)=0;

EV_c1(c,t)..
EV_LOAD(c,t) =e=
                 PTX_inv('ev',c)*cf_ev(t,c);

EV_c3(c,t)$(%ff%>0 and ord(t)=1)..
PTX_SL('ev',c,t) =e=
                 0.5*%ff%*PTX_inv('ev',c)*char_c(c,'ev_c_cap')
                 + PTX_stor_in('ev',c,t)
                 - PTX_stor_out('ev',c,t)/0.95
                 - %ff%*EV_LOAD(c,t);

EV_c33(c,t)$(%ff%>0 and ord(t)>1)..
PTX_SL('ev',c,t) =e=
                 PTX_SL('ev',c,t-1)
                 + PTX_stor_in('ev',c,t)
                 - PTX_stor_out('ev',c,t)/0.95
                 - %ff%*EV_LOAD(c,t);

EV_c5(c,t)..
PTX_SL('ev',c,t) =l=
                 %ff%*PTX_inv('ev',c)*char_c(c,'ev_c_cap');

EV_c6(c,t)..
PTX_stor_in('ev',c,t) =l=
                 %ff%*PTX_inv('ev',c)*char_c(c,'ev_c_power')*cf_ev_p(t,c);

EV_c7(c,t)..
PTX_stor_out('ev',c,t) =l=
                 %ff%*PTX_inv('ev',c)*char_c(c,'ev_c_power')*cf_ev_p(t,c);

EV_c8(c,t)$(ord(t)=card(t))..
PTX_SL('ev',c,t) =e=
                 0.5*%ff%*PTX_inv('ev',c)*char_c(c,'ev_c_cap');

EV_c9(c)..
PTX_inv('ev',c)*char_c(c,'ev_e_dem')/char_ptx('ev','eff_ptx') + ICE(c) =e=
                 char_c(c,'km_demand')
;

%NO_SC%$ontext
PTX_inv.lo('ev',c) = 0.5*char_c(c,'km_demand')*char_ptx('ev','eff_ptx')/char_c(c,'ev_e_dem')
$ontext
$offtext
;

Model Flex_mod / target_function
                 costs_country
                 energy_balance
                 LC_cost1
                 LC_cost2
                 IC_cost
                 DC_cost
                 DSM_cvar
                 GEN_c1
                 GEN_C2
                 GEN_C3
                 CSP_c1
                 CSP_c2
                 CSP_c3
                 CSP_c4
                 RES_c1
                 STOR_c1
                 STOR_c11
                 STOR_c2
                 STOR_c3
                 STOR_c4
                 NTC_c1
                 NTC_c2
                 DSM_c1
                 DSM_c2
                 DSM_c3
                 DSM_c4
                 DSM_c5
                 SHE_c1
                 SHE_c2
                 PTX_c1
                 PTH_c11
                 PTH_c12
                 PTH_c3
                 PTH_c4
                 PTH_c44
                 PTH_c5
                 PTH_c6
                 PTG_c12
                 PTG_c5
                 PTG_c3
                 EV_c1
                 EV_c9
%NO_SC%$ontext
                 PTH_c13
                 PTH_c2
                 PTH_c7
                 PTG_c13
                 PTG_c2
                 PTG_c4
                 PTG_c44
                 PTG_c6
                 PTG_c7
                 EV_c3
                 EV_c33
                 EV_c5
                 EV_c6
                 EV_c7
                 EV_c8
$ontext
$offtext
                     /;

$onecho > cplex.opt
lpmethod         4
threads          4
epopt            1e-5
eprhs            1e-5
parallelmode     -1
barepcomp        1e-5
barcrossalg      -1

$offecho
COMP.optfile=1;

solve Flex_mod using lp minimizing TOTAL_COSTS;
execute_unload "%DATE1%_ALL_RESULT_%PW_SHARE%_%co2pr%_%rs%_fs%ff%_sc%coup%_sto20.gdx"



