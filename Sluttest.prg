1 '
2 ' Avsluttende pr�ve i Robotteknikk.
3 ' 
4 ' H�sten 2022.
5 '
6 ' Navn: Kenneth Paulsen
7 '
8 '
9 ' ----------------------------------------- Programmets hensikt -----------------------------------------
10 '
11 ' Dette programmet skal flytte klosser fra stasjon 1 (bord med 4 bein)
12 ' til stasjon 3 (smalt bord p� motsatt side).
13 ' Klossene ligger i en pallett p� 3x3 i stasjon 1.
14 ' I stasjon 3 skal klossene settes etter hverandre p� h�ykant i en rett linje.
15 '
16 '
17 ' -------------------------------------- Kommentarer til programmet --------------------------------------
18 '
19 ' Jeg har variert bruken av Mov og Mvs. Mvs er kun brukt der jeg ans� det som hensiktsmessig. 
20 ' Alle posisjoner som har koordinater er satt til FLG1 = 7(Non-Flip), slik unngikk jeg at armen roterte
21 ' s� mye ved flytting. 
22 ' 
23 ' Posisjonene Plasser, PlasserOver og Plukk er alle tomme ved start. Posisjonene genereres automatisk av 
24 ' programmet om de slettes, lukker RT Toolbox og �pner programmet p� nytt. 
25 '
26 ' Ved plassering av klossene p� bordet g�r armen ned i bordet p� stasjon 3. For � unng� dette har jeg laget
27 ' en ny h�nd / griper (M_Tool = 2). Forskjellen er at verkt�yet griper klossen lengre opp.
28 ' Programmet l�fter klossene fra stasjon 1 og setter de ned p� enden av stasjon 3 (der armen ikke g�r i bordet), 
29 ' deretter tar roboten et nytt grep lengre opp p� klossen og flytter den til riktig plass. Jeg kunne valgt �
30 ' gripe klossen lengre opp allerede i stasjon 1, men det var �rlig talt ikke like g�y! :-)
31 '
32 ' P� grunn av den ekstra h�nden legger jeg ved hele workspace-mappen i tilfelle du skulle f� problemer med �
33 ' �pne/kj�re programmet uten riktig layout. 
34 ' 
35 ' Som f�lger av det nye grepet p� klossen er posisjonene til stasjon 3 forskj�vet tilsvarende (+20 i Z).
36 '
37 ' For � regulere hastigheten og hastighetsendringene i programmet har jeg skrevet egne subrutiner for � endre 
38 ' parametrene / variablene til hastighet og hastighetsendring. I en tidligere versjon av programmet brukte jeg
39 ' en Select Case og en IF styrt av variabel MHastighet = 1, 2, 3 osv. for � velge hastighet og hastighetsendring, 
40 '
41 ' omtrent:  
42 '           MHastighet = 1
43 '           Select MHastighet
44 '           Case Is 1
45 '              Accel 10, 5
46 '              Ovrd MSpdL
47 '              Dly MventKort
48 '              Break
49 '            Case Is 2
50 '             osv....
51 ' men det ble s�pass uoversiktlig og lite effektivt til slutt at jeg skrev om koden til � bruke subrutiner istedenfor.
52 ' Subrutinene st�r helt til slutt i koden, etter End
53 '
54 ' Man g�r inn i en subrutine ved � kj�re kommandoen GoSub *<subrutinens navn> 
55 ' Subrutinen er merket med *<subrutinens navn>. Subrutinen gj�r alt som st�r mellom *<subrutinens navn> og Return.
56 ' For � g� ut av subrutinen kj�rer man kommandoen Return. Man g�r da tilbake til kodelinjen etter den GoSub som 
57 ' ble aktivert.
58 '
59 '
60 '---------------- Versjon 2.1 ----------------
61 ' Endret fra 1.0 til 2.1
62 ' - Skrevet om hastighetsstyring fra Select Case til GoSub
63 ' - Fjernet kommandoer som l� dobbelt i For-loop og if/else
64 ' - Justert hastigheter og Accel
65 ' - Endret enkelte variabelnavn
66 ' - Funnet to feil valgt Mov/Mvs
67 '
68 '
69 '---------- Setter oppstartsverdier ----------
70 '
71 M_Tool = 1                  ' Velger gripeverkt�y. Dette er den "vanlige" h�nden
72 ' M_Tool = 2                ' Dette er den modifiserte h�nden som holder klossen lengre opp, for �yeblikket ikke aktivert
73 '
74 '
75 For MKloss = 1 To 9         ' Viser klossene p� riktig plass
76     M_Out(10 + MKloss) = 1  ' Vis klosser i stasjon 1
77     M_Out(30 + MKloss) = 0  ' Skjul klosser i stasjon 3
78 Next MKloss                 ' MKloss + 1
79 '
80 '
81 ' Definerer variabler for hastigheter og hastighetsendringer (akselerasjon og retardasjon)
82 MSpdH = 70
83 MSpdM = 40
84 MSpdL = 3
85 '
86 '
87 ' Definerer ventetider
88 MventKort = 0.3
89 MventLang = 0.5
90 '
91 '
92 ' Definerer palletter
93 Def Plt 1, Pallet1_1, Pallet1_2, Pallet1_3, , 3, 3, 2   ' Stasjon 1. 3x3 m�nster som plukkes i samme retning
94 Def Plt 2, Pallet2_1, Pallet2_2, Pallet2_3, , 9, 1, 3   ' Stasjon 3. 9x1 m�nster som plasseres som Arc. Legges i samme retning
95 '
96 ' ---------- Ferdig med oppstartsverdier ----------
97 '
98 '
99 ' ----------------- Programkode -------------------
100 '
101 '
102 '
103 GoSub *hoyHastighet             ' Aktiverer subrutine for h�y hastighet
104 Mov P01                         ' G�r til fellespunkt over stasjon 1
105 HOpen 1                         ' �pner verkt�yet
106 Dly MventLang                   ' Venter varigheten satt av variabel MventLang
107 '
108 '
109 ' ----- FOR-loop som skal plukke klossene i stasjon 3 og sette de ned p� kanten av stasjon 3 -----
110 For M1 = 1 To 9                 ' M1=1, kj�rer koden og legger til 1 p� M1
111     Plukk = Plt 1, M1           ' Lager variabel Plukk lik pallet 1, variabel M1
112     Mov Plukk, -100             ' G�r letteste vei til 100 over klossen som skal plukkes
113     GoSub *lavHastighet         ' Aktiverer subrutine for lav hastighet
114     Mvs Plukk                   ' G�r i en rett linje ned
115     Dly MventKort               ' Venter varigheten satt av variabel MventKort
116     HClose 1                    ' Lukker griperen
117     Dly MventKort               ' Venter varigheten satt av variabel MventKort
118     M_Out(10 + M1) = 0          ' Skrur av visning av den aktuelle klossen
119     Mvs Plukk, -100             ' G�r i en rett linje opp
120     Dly MventKort               ' Venter varigheten satt av variabel MventKort
121     GoSub *hoyHastighet         ' Aktiverer subrutine for h�y hastighet
122     '
123     ' --- Flytter klossen mot stasjon 3 ---
124     Mov Pallet2_3               ' G�r letteste vei til posisjon Pallet2_3 (p� enden av stasjon 3)
125     GoSub *lavHastighet         ' Aktiverer subrutine for lav hastighet
126     Mvs PMellomStasjon          ' G�r rett ned til posisjon PMellomStasjon, dette er nede p� bordet
127     Dly Mwati1                  ' Venter varigheten satt av variabel MventKort
128     M_Out(31) = 1               ' Skrur p� visning av kloss 31 (siste kloss p� stasjon 3)
129     HOpen 1                     ' �pner griperen
130     Dly MventKort               ' Venter varigheten satt av variabel MventKort
131 '
132 '
133 ' ----- Hvis M1 er mindre enn 9 plasseres klossene p� stasjon 3, slipper grepet, g�r litt opp og tar nytt grep -----
134     If M1 <9 Then
135         '
136         Mvs Pallet2_3                               ' G�r i en rett linje opp til posisjon Pallet2_3
137         M_Tool = 2                                  ' Bytter verkt�y til den endrede griperen
138         HClose 1                                    ' Lukker griperen
139         M_Out(31) = 0                               ' Skrur p� visning av kloss 31 (siste kloss p� stasjon 3)
140         '
141         PMellomStasjon.Z = PMellomStasjon.Z + 50    ' Legger til 50 i PMellomStasjon sin Z.
142         Dly MventKort                               ' Venter varigheten satt av variabel MventKort
143         Mvs PMellomStasjon                          ' G�r i en rett linje opp til PMellomStasjon (som n� er 50 h�yere)
144         PMellomStasjon.Z = PMellomStasjon.Z - 50    ' Trekker fra 50 i Z slik at det ikke akkumuleres for hver gjennomkj�ring
145         GoSub *mediumHastighet                      ' Aktiverer subrutine for medium hastighet
146         '
147         '
148         ' ---Plasserer klossen ned p� riktig plass p� stasjon 3 ---
149         Plasser = Plt 2, M1                     ' Lager variabel Plasser, som er lik Pallet 2, styrt av M1
150         PlasserOver = Plasser                   ' Lager variabelen PlasserOver og setter den lik Plasser
151         PlasserOver.Z = PMellomStasjon.Z + 50   ' Henter Z fra PlasserOver og skriver ny Z til PMellomstasjon og legger til 50
152         '
153         Mov PlasserOver                         ' G�r letteste vei til posisjonen PlasserOver
154         GoSub *lavHastighet                     ' Aktiverer subrutine for lav hastighet
155         Mvs Plasser                             ' G�r i en rett linje opp til posisjon Plasser
156         '
157         Dly MventKort                           ' Venter varigheten satt av variabel MventKort
158         M_Out(40 - M1) = 1                      ' Skrur p� visning av klossen som tilsvarer M1 (klossene er 39-31)
159         HOpen 1                                 ' �pner griperen
160         M_Tool = 1                              ' Bytter verkt�y tilbake til den "vanlige"
161         GoSub *mediumHastighet                  ' Aktiverer subrutine for medium hastighet 
162         '
163         PlasserOver.Z = Plasser.Z + 80          ' Henter Z fra PlasserOver og skriver ny Z til Plasser og legger til 80
164         Mvs PlasserOver                         ' Denne kan sl�yfes for � g� rett ut i armens Z etter at man slipper klossen
165         '
166         '
167 ' ----- Hvis M1 er st�rre enn 9 (siste kloss) er det ikke n�dvendig � ta nytt grep ----- 
168     Else 
169         '
170         PlasserOver.Y = Pallet2_3.Y             ' Henter Y fra plasserOver og skriver den til Y i Pallet 2_3. Om denne ...
171                                                 ' ... ikke kj�res vil armen g� "inn" i klossen etter at den slipper klossen. 
172         Mvs PlasserOver                         ' G�r opp for � g� klar for klossen.
173         Dly MventKort                            ' Venter varigheten satt av variabel MventKort
174         '
175         '
176     EndIf                                       ' Slutt p� IF
177     '
178     '
179     GoSub *hoyHastighet                         ' Aktiverer subrutine for h�y hastighet 
180 '
181 Next M1                                         ' Legger til 1 p� M1 og om n�dvendig tilbake til toppen av For-loopen
182 '
183 Mov P01                                         ' G�r til fellespunkt over stasjon 1 
184 '
185 '
186 ' --------- Ferdig med programkode --------
187 End                                             ' Programmet er ferdig
188 '
189 '
190 ' --------------- Subrutiner ---------------
191 '
192 ' ----- Subrutine som setter lav hastigheten og retarderer  -----
193 *lavHastighet           ' Navnet p� subrutinen
194     Accel 10, 5         ' Setter robotens akselerasjon lik 10% og retardasjon lik 5% Roboten vil da akselerer sakte og bremse
195     Ovrd MSpdL          ' Setter den generelle hastigheten lik variabelen MSpdL (3)
196     Dly MventLang       ' Venter varigheten satt av variabel MventLang. Inkluderte denne her for � spare kodelinjer
197 Return                  ' Subrutine slutt, g�r tilbake til linjen etter at den ble aktivert
198 '
199 '
200 ' ----- Subrutine som setter medium hastighet og medium aks. ret. -----
201 *mediumHastighet        ' Navnet p� subrutinen
202     Accel 50, 30        ' Setter robotens akselerasjon lik 50% og retardasjon lik 30%
203     Ovrd MSpdM          ' Setter den generelle hastigheten lik variabelen MSpdM (40)
204     Dly MventKort       ' Venter varigheten satt av variabel MventKort. Inkluderte denne her for � spare kodelinjer
205 Return                  ' Subrutine slutt, g�r tilbake til linjen etter at den ble aktivert
206 '
207 '
208 ' ----- Subrutine som setter h�y hastighet og aks. ret. -----
209 *hoyHastighet           ' Navnet p� subrutinen
210     Accel 70, 50        ' Setter robotens akselerasjon lik 70% og retardasjon lik 50%
211     Ovrd MSpdH          ' Setter den generelle hastigheten lik variabelen MSpdH (70)
212     Dly MventKort       ' Venter varigheten satt av variabel MventKort. Inkluderte denne her for � spare kodelinjer
213 Return                  ' Subrutine slutt, g�r tilbake til linjen etter at den ble aktivert
214 '
215 '
216 '
217 '
218 '
219 '
220 '
221 '
Pallet1_1=(-410.00,-170.00,+100.00,+180.00,+0.00,-90.00)(7,0)
Pallet1_2=(-190.00,-170.00,+100.00,+180.00,+0.00,-90.00)(7,0)
Pallet1_3=(-410.00,-430.00,+100.00,+180.00,+0.00,-90.00)(7,0)
Pallet2_1=(+300.00,+160.00,+150.00,+90.00,+0.00,+180.00)(7,0)
Pallet2_2=(+300.00,+0.00,+150.00,+90.00,+0.00,+180.00)(7,0)
Pallet2_3=(+300.00,-160.00,+150.00,+90.00,+0.00,+180.00)(7,0)
P01=(+0.00,-400.00,+300.00,+180.00,+0.00,+0.00)(7,0)
Plukk=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PMellomStasjon=(+300.00,-160.00,+130.00,+90.00,+0.00,+180.00)(7,0)
Plasser=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
PlasserOver=(+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00,+0.00)(,)
