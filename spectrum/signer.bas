   10 DEF FN h$(d)="0123456789ABCDEF"(d+1): DEF FN f$(a)=STR$ USR 59994: DEF FN n$(a$)=STR$ USR 59997: DEF FN r$(a$)=(CHR$ 128 AND a$="")+(CHR$ 129 AND LEN a$=1 AND a$>"\*")+(CHR$ (128+LEN a$ AND LEN a$<56) AND LEN a$<56 AND LEN a$>1)+(CHR$ (184+(LEN a$>255)) AND LEN a$>55)+(CHR$ INT (LEN a$/256) AND LEN a$>255)+(CHR$ (LEN a$-256*INT (LEN a$/256)) AND LEN a$>55)+a$
   20 DEF FN l$(a$)=(CHR$ (192+LEN a$ AND LEN a$<56) AND LEN a$<56)+(CHR$ (248+(LEN a$>255)) AND LEN a$>55)+(CHR$ INT (LEN a$/256) AND LEN a$>255)+(CHR$ (LEN a$-256*INT (LEN a$/256)) AND LEN a$>55)+a$: LET y$="ab9978946F329a525dE609f2c28C3A1e38128fF2"
   30 INPUT "Private key:"'"" AND USR 60009; LINE k$
   40 PRINT "Deriving address...": IF USR 60006 THEN BEEP 1,0: GO TO 30
   50 INPUT #15;a$: RANDOMIZE USR 60003
   60 CLS : PRINT AT 18,0;"address:"' BRIGHT 1;a$: LET q$="ethereum:"+a$: RANDOMIZE USR 59991
   70 INPUT "Use this key?[y] "; LINE c$: LET c$=c$( TO 0<LEN c$): IF c$="n" OR c$="N" THEN GO TO 30
   80 INPUT "Message or Tx?[m] "; LINE c$: LET c$=c$( TO 0<LEN c$): IF c$="t" OR c$="T" THEN GO TO 180
   90 INPUT "Message to sign:"' LINE m$
  100 PRINT "msg:"' BRIGHT 1;m$
  110 PRINT #15;CHR$ 25;"Ethereum Signed Message:";CHR$ 10;STR$ LEN m$;m$;
  120 RANDOMIZE USR 60012
  130 INPUT #15;s$
  140 PRINT "sig:"' BRIGHT 1;s$
  150 PRINT "version: "; BRIGHT 1;2
  160 PRINT #1;"Press any key to continue.": PAUSE 0
  170 GO TO 60
  180 LET f$=a$: INPUT "nonce? ";nonce'"gas price in GWei?[50] "; LINE p$'"gas limit?[21000] "; LINE l$'"to?[donate to author]"' LINE a$'"value in ETH? ";value'"data? "; LINE d$
  190 IF nonce<0 THEN GO TO 180
  200 IF p$="" THEN LET p$="50"
  210 LET gas price=VAL (p$+"e9")
  220 IF l$="" THEN LET l$="21000"
  230 IF a$="" THEN LET a$=y$
  240 IF LEN d$>1 THEN IF d$(1)="""" AND d$(LEN d$)="""" THEN LET x$=d$(2 TO LEN d$-1): GO TO 260
  250 LET x$=FN n$(d$)
  260 LET addr check=USR 60003
  270 IF value<0 THEN GO TO 180
  280 PRINT "nonce:"' BRIGHT 1;nonce
  290 PRINT "gas price:"' BRIGHT 1;gas price; BRIGHT 0;" Wei"
  300 PRINT "gas limit:"' BRIGHT 1;l$
  310 PRINT "to:"; INK (2 AND addr check)+(a$=y$) ' BRIGHT 1;a$; BRIGHT 0;" "+("(donation to author)" AND a$=y$)+("CHECKSUM ERROR" AND addr check)
  320 PRINT "value:"' BRIGHT 1;value; BRIGHT 0;" ETH"
  330 PRINT "data:"' BRIGHT 1;d$
  340 INPUT "Sign transaction?[n] "; LINE c$: LET c$=c$( TO 0<LEN c$): IF c$<>"y" AND c$<>"Y" THEN LET a$=f$: GO TO 60
  350 LET t$=FN r$(FN f$(nonce))+FN r$(FN f$(gas price))+FN r$(FN n$(l$))+FN r$(FN n$("0x"+a$))+FN r$(FN f$(value *1e18))+FN r$(x$)
  360 PRINT "Signing transaction..."
  370 PRINT #15;FN l$(t$+CHR$ 1+CHR$ 128+CHR$ 128);
  380 RANDOMIZE USR 60012
  390 INPUT #15;s$
  400 LET v$=s$(129 TO )
  410 IF v$="1B" THEN LET v$="25"
  420 IF v$="1C" THEN LET v$="26"
  430 LET t$=t$+FN r$(FN n$("0x"+v$))+FN r$(FN n$("0x"+s$( TO 64)))+FN r$(FN n$("0x"+s$(65 TO 128)))
  440 LET t$=FN l$(t$)
  450 CLS : PRINT #1;AT 0,0;"Signed RLP:"' BRIGHT 1;"0x";: LET q$="https://etherscan.io/pushTx?hex=0x"
  460 FOR i=1 TO LEN t$: LET c=CODE t$(i): LET h=INT (c/16): LET h$=FN h$(h)+FN h$(c-16*h): PRINT #1; BRIGHT 1;h$;: LET q$=q$+h$: NEXT i: BRIGHT 0
  470 IF LEN t$>112 THEN PAUSE 0: CLS 
  480 PRINT #1: IF LEN q$<=321 THEN RANDOMIZE USR 59991
  490 LET a$=f$: PAUSE 0: GO TO 60
