
*=== iRES expanion model =======================================================
*=== author: Christoph Zöphel ==================================================
*=== last update: 25.06.2021 ===================================================


option profile=1
option reslim = 1E9;

*=============================================================
*       Declaration of Sets, Parameters, Varables and Equations
*=============================================================*

$set scen HW
$set max_res 1.1
$set min_res 0.5
$set row 2
$set col B
$ontext
$offtext

$ifthen "%scen%" == "HP"
Scalar
pvshare                  /0.5/
woffshare_max            /0.25/
woffshare_min            /0.05/
;
$endif

$ifthen "%scen%" == "60"
Scalar
pvshare                  /0.4/
woffshare_max            /0.30/
woffshare_min            /0.10/
;
$endif

$ifthen "%scen%" == "REF"
Scalar
pvshare                  /0.3/
woffshare_max            /0.35/
woffshare_min            /0.15/
;
$endif

$ifthen "%scen%" == "80"
Scalar
pvshare                  /0.2/
woffshare_max            /0.40/
woffshare_min            /0.20/
;
$endif

$ifthen "%scen%" == "HW"
Scalar
pvshare                  /0.1/
woffshare_max            /0.45/
woffshare_min            /0.25/
;
$endif


set

ch_p                     list of RES characteristics (directly read from excel)
ch_c                     list of country specific characteristics (directly read from excel)
ch_r                     list of raster characteristics
p                        list of RES plants (directly read from excel)
c                        country
r                        list of raster data
nlu(r)                   all countries except LU

map_rc(r,c)              map raster to country
map_rw(r,p)              map raster to RES technology

t                        modelling hours /t1*t8760/
;

alias (c, cc)
(r,rr);

Scalar
res_tshare               assumption: total RES-Share on electricity demand       /0.8/
i                        interest rate                                           /0.07/
;

parameters
char_c(c,ch_c)           countrie specific characteristics
char_p(p,ch_p)           iRES technology specific characteristics
char_r(r,ch_r)           raster specific characteristics
TOTAL_DEM                total electricity demand

cf_pv                    capacity factors for PV
cf_won                   capacity factors for wind onshore
cf_woff                  capacity factors for wind offshore

anf                      annuity factor
an                       annuity

dem                      electricity demand
;

Variables
TOTAL_COSTS              total costs [€]
;

Positive variables
C_PV_si                  Installed capacity of PV (single raster)
C_PV_bo                  installed capacity of PV (shared raster with won)
C_WON_si                 Installed capacity of wind onshore (single raster)
C_WON_bo                 Installed capacity of wind onshore (shared raster with PV)
C_WOFF                   Installed capacity of wind offshore (single raster)

TOTAL_PV                 Total installed capacity of PV
TOTAL_WON                Total installed capacity of wind onshore
TOTAL                    Total installed capacity of PV and wind onshore
TOTAL_WOFF               Total installed capacity of wind offshore

G_PV                     Generation of PV
G_WON                    Generation of wind onshore
G_WOFF                   Generation of wind offshore

INV_RES                  Total investments in iRES capacity
apv                      penalty capacities for PV
awon                     penalty capacities for wind onshore
;

Equations
target_function
invest_res
sum_pv_cap
sum_won_cap
sum_woff_cap
sum_e
share_res
share_pv
share_woff_max
share_pv_FR
share_pv_ES
min_share
max_share
max_pv_share_c
max_won_share_c
max_woff_share_c
min_cap_pv
min_cap_won
min_cap_woff
max_woff_share_c
land_use_bo
max_share_rast_PV
max_share_rast_WON
;

*=============================================================
*       Data Input
*=============================================================

*============unload data to GDX file ====================
$onecho >temp1.tmp
set=p            rng=RES_char!A4         rdim=1  cdim=0
set=c            rng=c_char!A4           rdim=1  cdim=0
set=r            rng=coordinates!A3      rdim=1  cdim=0
set=ch_p         rng=RES_char!A2         rdim=0  Cdim=1
set=ch_c         rng=c_char!A3           rdim=0  Cdim=1
set=ch_r         rng=coordinates!A2      rdim=0  Cdim=1
set=map_rc       rng=coordinates!T2      Rdim=2  cdim=0
set=map_rw       rng=coordinates!V2      Rdim=2  cdim=0
Par=char_p       rng=RES_char!A2         Rdim=1  cdim=1
Par=char_c       rng=c_char!A3           Rdim=1  cdim=1
Par=char_r       rng=coordinates!A2      Rdim=1  cdim=1
Par=dem          rng=demand!A1           Rdim=1  Cdim=1

$offecho


$onUNDF
$IF NOT EXIST raster_data.gdx $call "gdxxrw data\raster_data.xlsx SQ=N SE=10 cmerge=1 @temp1.tmp"
$gdxin raster_data.gdx
$load p c r ch_p ch_c ch_r map_rc map_rw
$load char_p char_c char_r dem
$gdxin
$offUNDF


$onecho >temp2.tmp
par=cf_pv        rng=cf_pv!A1           Rdim=1  Cdim=1

$offecho

$onUNDF
$IF NOT EXIST cf_pv.gdx $call "gdxxrw data\cf_pv.xlsx SQ=N SE=10 cmerge=1 @temp2.tmp"
$gdxin cf_pv.gdx
$load cf_pv
$gdxin
$offUNDF

$onecho >temp3.tmp
par=cf_won       rng=cf_won!A1          Rdim=1  Cdim=1

$offecho

$onUNDF
$IF NOT EXIST cf_won_190808.gdx $call "gdxxrw data\cf_won_190808.xlsx SQ=N SE=10 cmerge=1 @temp3.tmp"
$gdxin cf_won_190808.gdx
$load cf_won
$gdxin
$offUNDF

$onecho >temp4.tmp
par=cf_woff      rng=cf_woff!A1         Rdim=1  Cdim=1

$offecho

$onUNDF
$IF NOT EXIST cf_woff.gdx $call "gdxxrw data\cf_woff.xlsx SQ=N SE=10 cmerge=1 @temp4.tmp"
$gdxin cf_woff.gdx
$load cf_woff
$gdxin
$offUNDF


nlu(r)=YES$(char_r(r,'lu_not')=1);
anf(p)=               ((1+i)**char_p(p,'lt')*i)/((1+i)**char_p(p,'lt')-1);
an(p)=                char_p(p,'inv')*anf(p);

TOTAL_DEM=sum(c,char_c(c,'dem_total'));

*=============================================================
*                Model calculation
*=============================================================

*==========target function====================
target_function..
TOTAL_COSTS =e=
                 sum(c, INV_RES(c))
;

invest_res(c)..
INV_RES(c) =e=
                 sum(r$map_rc(r,c),
                         C_PV_si(r)*an('PVr') + C_PV_bo(r)*an('PVu')
                         + sum(p$map_rw(r,p),(C_WON_si(r) + C_WON_bo(r))*an(p))
                         + apv(r)*2*((an('PVr')+an('PVu'))/2)
                         + sum(p$map_rw(r,p),awon(r)*2*an(p)))
                 + C_WOFF(c)*an('Woff');

*=== set existing and new iRES pp ===============================================
sum_pv_cap(c)..
sum(r$map_rc(r,c), C_PV_si(r) + C_PV_bo(r)) =e= TOTAL_PV(c)
;

sum_won_cap(c)..
sum(r$map_rc(r,c), C_WON_si(r) + C_WON_bo(r)) =e= TOTAL_WON(c)
;

sum_woff_cap..
sum(c,C_WOFF(c)) =e= TOTAL_WOFF
;

sum_e(c)..
sum(r$map_rc(r,c), (C_PV_si(r) + C_PV_bo(r))*char_r(r,'VLH_pv')) + sum(r$map_rc(r,c), (C_WON_si(r) + C_WON_bo(r))*char_r(r,'VLH_wind')) + C_WOFF(c)*char_c(c,'vlh_woff') =e= TOTAL(c)
;

*=== set total iRES shares ======================================================
share_res..
sum(c, TOTAL(c)) =e= res_tshare*TOTAL_DEM
;

share_pv..
sum(r, (C_PV_si(r) + C_PV_bo(r))*char_r(r,'VLH_pv')) =e=
                 res_tshare*pvshare*TOTAL_DEM
;

share_woff_max..
sum(c, C_WOFF(c)*char_c(c,'vlh_woff')) =l=
                 0.3*res_tshare*TOTAL_DEM
;

share_woff_min..
sum(c, C_WOFF(c)*char_c(c,'vlh_woff')) =g=
                 0.2*(1-pvshare)*res_tshare*TOTAL_DEM
;

share_pv_FR('FR')..
sum(r$map_rc(r,'FR'), (C_PV_si(r) + C_PV_bo(r)) * char_r(r,'VLH_pv')) =l= pvshare * TOTAL('FR')
;

share_pv_ES('ES')..
sum(r$map_rc(r,'ES'), (C_PV_si(r) + C_PV_bo(r)) * char_r(r,'VLH_pv')) =l= pvshare * TOTAL('ES')
;

*=== set maximal and minimal domestic iRES production ===========================
min_share(c)..
TOTAL(c) =g= (char_c(c,'start_share')+0.3)*char_c(c,'dem_total')
;

max_share(c)..
TOTAL(c) =l= %max_res%*char_c(c,'dem_total')
;

*=== set minimal and maximal installable Capacities in country =================
C_WOFF.up(c)=char_c(c,'max_woff');

max_pv_share_c(c)..
sum(r$map_rc(r,c), (C_PV_si(r) + C_PV_bo(r)) * char_r(r,'VLH_pv')) =l= 0.9 * TOTAL(c)
;

max_won_share_c(c)..
sum(r$map_rc(r,c), (C_WON_si(r) + C_WON_bo(r)) * char_r(r,'VLH_wind')) =l= 0.9 * TOTAL(c)
;

max_woff_share_c(c)..
C_WOFF(c)*char_c(c,'vlh_woff') =l= woffshare_max*TOTAL(c)
;

min_cap_pv(c)..
TOTAL_PV(c) =g= char_c(c,'min_PV')
;

min_cap_won(c)..
TOTAL_WON(c) =g= char_c(c,'min_won')
;

min_cap_woff(c)..
C_WOFF(c)   =g= char_c(c,'min_woff')
;

TOTAL_PV.up('NO')=10000;
TOTAL_PV.up('NO')=15000;

*=== limit iRES capacity expanion in single rasters ============================
C_PV_si.up(nlu) = char_r(nlu,'pv_area')*char_r(nlu,'a_spec_pv_r');
C_WON_si.up(nlu) = char_r(nlu,'wind_area')*char_r(nlu,'a_spec_won');

land_use_bo(nlu)..
C_PV_bo(nlu)/char_r(nlu,'a_spec_pv_u') + C_WON_bo(nlu)/char_r(nlu,'a_spec_won') =l= char_r(nlu,'both_area')
;

max_share_rast_PV(nlu,c)$map_rc(nlu,c)..
C_PV_si(nlu) + C_PV_bo(nlu) - apv(nlu) =l= char_r(nlu,'pv_wvlh')*TOTAL_PV(c)
;

max_share_rast_WON(nlu,c)$map_rc(nlu,c)..
C_WON_si(nlu) + C_WON_bo(nlu) - awon(nlu) =l= char_r(nlu,'wind_wvlh')*TOTAL_WON(c)
;




*=============================================================
*                Solving the Model
*=============================================================

Model ELTRAMOD   /target_function
                 invest_res
                 sum_pv_cap
                 sum_won_cap
                 sum_woff_cap
                 sum_e
                 share_res
                 share_pv
                 share_woff_max
                 share_pv_FR
                 share_pv_ES
                 min_share
                 max_share
                 max_pv_share_c
                 max_won_share_c
                 max_woff_share_c
                 min_cap_pv
                 min_cap_won
                 min_cap_woff
                 max_woff_share_c
                 land_use_bo
                 max_share_rast_PV
                 max_share_rast_WON

                 /;

solve ELTRAMOD using LP min TOTAL_COSTS;


*=============================================================
*               Output
*=============================================================


parameter

OUT_R_PV                         Installed PV capacities in raster [MW]
OUT_R_PV_si                      Installed PV capacities in raster not shared with wind onshore [MW]
OUT_R_PV_bo                      Installed PV capacities in raster shared with wind onshore [MW]
OUT_R_Won                        Installed Wind onshore capacities in raster  [MW]
OUT_R_Won_si                     Installed Wind onshore capacities in raster not shared with PV [MW]
OUT_R_Won_bo                     Installed Wind onshore capacities in raster shared with PV [MW]
OUT_C_Total_Woff                 Installed Wind offshore capacities in country [MW]
OUT_SHARE_country_area           Share of available land used by iRES
OUT_GEN_SHARE_country            Share of iRES generation on country's electricity demand
OUT_SHARE_gen                    Total share of iRES generation on electricity demand in the observed region
OUT_GEN_R                        Total generation iRES in raster [MWh]
OUT_GEN_R_PV                     Generation of PV in raster [MWh]
OUT_GEN_C_PV                     Generation of PV in country [MWh]
OUT_GEN_C_PV_TOTAL               Total generation of PV [MWh]
OUT_GEN_R_WON                    Generation of wind onshore in raster [MWh]
OUT_GEN_C_WON                    Generation of wind onshore in country [MWh]
OUT_GEN_C_WON_TOTAL              Total generation of wind onshore [MWh]
OUT_GEN_C_WOFF                   Generation of wind offshore in country [MWh]
OUT_GEN_C_WOFF_TOTAL             Total generation of wind offshore [MWh]
OUT_GEN_country                  Total iRES generation in country [MWh]
OUT_GEN_Total                    Total generation of iRES [MWh]
OUT_GEN_TOTAL_T                  Total generation of iRES [MWh]
OUT_GEN_C_RESDEM                 Residual load of country [MWh]
OUT_GEN_TOTAL_RESDEM             Total residual load of the observed region [MWh]
OUT_MEAN                         Mean country's residual load
OUT_CORR_C                       Correlation coefficient between countries residual load
OUT_CORR                         Mean correlation coefficient
;

OUT_R_PV(r)=                     C_PV_si.l(r) + C_PV_bo.l(r)+1/10E9;
OUT_R_PV_si(r)=                  C_PV_si.l(r)+1/10E9;
OUT_R_PV_bo(r)=                  C_PV_bo.l(r)+1/10E9;

OUT_R_Won(r)=                    C_WON_si.l(r) + C_WON_bo.l(r)+1/10E9;
OUT_R_Won_si(r)=                 C_WON_si.l(r)+1/10E9;
OUT_R_Won_bo(r)=                 C_WON_bo.l(r)+1/10E9;

OUT_C_Total_Woff(c)=             C_WOFF.l(c);

OUT_SHARE_country_area(c)=       sum(r$map_rc(r,c),
                                         (C_PV_si.l(r)/char_r(r,'a_spec_pv_r') + C_PV_bo.l(r)/char_r(r,'a_spec_pv_u')
                                         +(C_WON_si.l(r) + C_WON_bo.l(r))/char_r(r,'a_spec_won'))) ;

OUT_GEN_country(c)=              sum(r$map_rc(r,c), (C_PV_si.l(r) + C_PV_bo.l(r))*char_r(r,'VLH_pv'))
                                 + sum(r$map_rc(r,c), (C_WON_si.l(r) + C_WON_bo.l(r))*char_r(r,'VLH_wind'))
                                 + C_WOFF.l(c)*char_c(c,'vlh_woff');
OUT_GEN_Total=                   sum(c,OUT_GEN_country(c));
OUT_GEN_SHARE_country(c)=        OUT_GEN_country(c)/char_c(c,'dem_total');
OUT_SHARE_gen=                   OUT_GEN_Total/TOTAL_DEM;

OUT_GEN_R_PV(t,r)=               (C_PV_si.l(r) + C_PV_bo.l(r))*cf_pv(t,r)+1/10E9;
OUT_GEN_C_PV(t,c)=               sum(r$map_rc(r,c), OUT_GEN_R_PV(t,r));
OUT_GEN_C_PV_TOTAL(c)=           sum(t,OUT_GEN_C_PV(t,c));
OUT_GEN_R_WON(t,r)=              (C_WON_si.l(r) + C_WON_bo.l(r))*cf_won(t,r)+1/10E9;
OUT_GEN_C_WON(t,c)=              sum(r$map_rc(r,c), OUT_GEN_R_WON(t,r));
OUT_GEN_C_WON_TOTAL(c)=          sum(t, OUT_GEN_C_WON(t,c));
OUT_GEN_C_WOFF(t,c)=             C_WOFF.l(c)*cf_woff(t,c)+1/10E9;
OUT_GEN_C_WOFF_TOTAL(c)=         sum(t, OUT_GEN_C_WOFF(t,c));

OUT_GEN_TOTAL_T(t,c)=            OUT_GEN_C_PV(t,c) + OUT_GEN_C_WON(t,c) + OUT_GEN_C_WOFF(t,c) ;
OUT_GEN_C_RESDEM(t,c)=           dem(t,c) - (OUT_GEN_C_PV(t,c) + OUT_GEN_C_WON(t,c) + OUT_GEN_C_WOFF(t,c));
OUT_GEN_TOTAL_RESDEM(t)=         sum(c, OUT_GEN_C_RESDEM(t,c));

OUT_MIN=                         smin(t,OUT_GEN_TOTAL_RESDEM(t));
OUT_NEG_E_t(t)=                  OUT_GEN_TOTAL_RESDEM(t)$(OUT_GEN_TOTAL_RESDEM(t)<0);
OUT_NEG_E=                       sum(t,OUT_NEG_E_t(t));
OUT_NEG_H=                       card(OUT_NEG_E_t);

OUT_MEAN(c)=                     sum(t, OUT_GEN_C_RESDEM(t,c))/card(t);
OUT_CORR_C(c,cc)$(ord(cc)>ord(c))=
                                 sum(t, (OUT_GEN_C_RESDEM(t,c) - OUT_MEAN(c))*(OUT_GEN_C_RESDEM(t,cc) - OUT_MEAN(cc)))/sqrt(sum(t, sqr(OUT_GEN_C_RESDEM(t,c) - OUT_MEAN(c)))*sum(t, sqr(OUT_GEN_C_RESDEM(t,cc) - OUT_MEAN(cc))));
OUT_CORR=                        sum((c,cc), OUT_CORR_C(c,cc))/card(OUT_CORR_C);

execute_unload "OUT_iRES_extension.gdx"

$onecho >out.txt

SQ=N par=OUT_R_PV                rng=results_%scen%!A1 rdim=1  cdim=0
SQ=N par=OUT_R_Won               rng=results_%scen%!E1 rdim=1  cdim=0
SQ=N par=OUT_R_PV_si             rng=results_%scen%_2!A1 rdim=1  cdim=0
SQ=N par=OUT_R_PV_bo             rng=results_%scen%_2!C1 rdim=1  cdim=0
SQ=N par=OUT_R_Won_si            rng=results_%scen%_2!E1 rdim=1  cdim=0
SQ=N par=OUT_R_Won_bo            rng=results_%scen%_2!G1 rdim=1  cdim=0
SQ=N par=OUT_C_Total_Woff        rng=results_%scen%!H1 rdim=1  cdim=0
SQ=N par=OUT_SHARE_country_area  rng=results_%scen%!K1 rdim=1  cdim=0
SQ=N par=OUT_GEN_SHARE_country   rng=results_%scen%!N1 rdim=1  cdim=0
SQ=N par=OUT_SHARE_gen           rng=results_%scen%!Q1
SQ=N par=OUT_GEN_TOTAL_RESDEM    rng=RL_%scen%!A1 rdim=1  cdim=0
SQ=N par=OUT_GEN_C_RESDEM        rng=RL_%scen%!D1
SQ=N par=OUT_GEN_C_PV            rng=RL_%scen%!X1
SQ=N par=OUT_GEN_C_WON           rng=RL_%scen%!AR1
SQ=N par=OUT_GEN_C_WOFF          rng=RL_%scen%!BL1
SQ=N par=OUT_GEN_C_PV_TOTAL      rng=results_%scen%!T1 rdim=1  cdim=0
SQ=N par=OUT_GEN_C_WON_TOTAL     rng=results_%scen%!W1 rdim=1  cdim=0
SQ=N par=OUT_GEN_C_WOFF_TOTAL    rng=results_%scen%!Z1 rdim=1  cdim=0
SQ=N par=OUT_GEN_TOTAL_T         rng=RL_%scen%!CE1
SQ=N par=OUT_CORR                rng=Corr!%col%%row%

$offecho

execute 'gdxxrw.exe OUT_iRES_extension.gdx o=OUT_iRES_extension.xlsx @out.txt';

$stop

