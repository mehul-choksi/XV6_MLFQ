
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	d5010113          	add	sp,sp,-688 # 80009d50 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	sllw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	1761                	add	a4,a4,-8 # 200bff8 <_entry-0x7dff4008>
    8000003a:	6318                	ld	a4,0(a4)
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	sll	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	sll	a3,a3,0x3
    80000050:	0000a717          	auipc	a4,0xa
    80000054:	bc070713          	add	a4,a4,-1088 # 80009c10 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	75e78793          	add	a5,a5,1886 # 800067c0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	add	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	add	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd9757>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e2678793          	add	a5,a5,-474 # 80000ed2 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srl	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	add	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	add	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	f84a                	sd	s2,48(sp)
    80000108:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    8000010a:	04c05663          	blez	a2,80000156 <consolewrite+0x56>
    8000010e:	fc26                	sd	s1,56(sp)
    80000110:	f44e                	sd	s3,40(sp)
    80000112:	f052                	sd	s4,32(sp)
    80000114:	ec56                	sd	s5,24(sp)
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	add	a0,s0,-65
    8000012a:	00003097          	auipc	ra,0x3
    8000012e:	95c080e7          	jalr	-1700(ra) # 80002a86 <either_copyin>
    80000132:	03550463          	beq	a0,s5,8000015a <consolewrite+0x5a>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	7e4080e7          	jalr	2020(ra) # 8000091e <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addw	s2,s2,1
    80000144:	0485                	add	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    8000014c:	74e2                	ld	s1,56(sp)
    8000014e:	79a2                	ld	s3,40(sp)
    80000150:	7a02                	ld	s4,32(sp)
    80000152:	6ae2                	ld	s5,24(sp)
    80000154:	a039                	j	80000162 <consolewrite+0x62>
    80000156:	4901                	li	s2,0
    80000158:	a029                	j	80000162 <consolewrite+0x62>
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	79a2                	ld	s3,40(sp)
    8000015e:	7a02                	ld	s4,32(sp)
    80000160:	6ae2                	ld	s5,24(sp)
  }

  return i;
}
    80000162:	854a                	mv	a0,s2
    80000164:	60a6                	ld	ra,72(sp)
    80000166:	6406                	ld	s0,64(sp)
    80000168:	7942                	ld	s2,48(sp)
    8000016a:	6161                	add	sp,sp,80
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	add	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	add	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	bc450513          	add	a0,a0,-1084 # 80011d50 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	aa4080e7          	jalr	-1372(ra) # 80000c38 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	bb448493          	add	s1,s1,-1100 # 80011d50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	00012917          	auipc	s2,0x12
    800001a8:	c4490913          	add	s2,s2,-956 # 80011de8 <cons+0x98>
  while(n > 0){
    800001ac:	0d305763          	blez	s3,8000027a <consoleread+0x10c>
    while(cons.r == cons.w){
    800001b0:	0984a783          	lw	a5,152(s1)
    800001b4:	09c4a703          	lw	a4,156(s1)
    800001b8:	0af71c63          	bne	a4,a5,80000270 <consoleread+0x102>
      if(killed(myproc())){
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	9ce080e7          	jalr	-1586(ra) # 80001b8a <myproc>
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	70c080e7          	jalr	1804(ra) # 800028d0 <killed>
    800001cc:	e52d                	bnez	a0,80000236 <consoleread+0xc8>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	2fe080e7          	jalr	766(ra) # 800024d0 <sleep>
    while(cons.r == cons.w){
    800001da:	0984a783          	lw	a5,152(s1)
    800001de:	09c4a703          	lw	a4,156(s1)
    800001e2:	fcf70de3          	beq	a4,a5,800001bc <consoleread+0x4e>
    800001e6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e8:	00012717          	auipc	a4,0x12
    800001ec:	b6870713          	add	a4,a4,-1176 # 80011d50 <cons>
    800001f0:	0017869b          	addw	a3,a5,1
    800001f4:	08d72c23          	sw	a3,152(a4)
    800001f8:	07f7f693          	and	a3,a5,127
    800001fc:	9736                	add	a4,a4,a3
    800001fe:	01874703          	lbu	a4,24(a4)
    80000202:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000206:	4691                	li	a3,4
    80000208:	04db8a63          	beq	s7,a3,8000025c <consoleread+0xee>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    8000020c:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	faf40613          	add	a2,s0,-81
    80000216:	85d2                	mv	a1,s4
    80000218:	8556                	mv	a0,s5
    8000021a:	00003097          	auipc	ra,0x3
    8000021e:	816080e7          	jalr	-2026(ra) # 80002a30 <either_copyout>
    80000222:	57fd                	li	a5,-1
    80000224:	04f50a63          	beq	a0,a5,80000278 <consoleread+0x10a>
      break;

    dst++;
    80000228:	0a05                	add	s4,s4,1
    --n;
    8000022a:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    8000022c:	47a9                	li	a5,10
    8000022e:	06fb8163          	beq	s7,a5,80000290 <consoleread+0x122>
    80000232:	6be2                	ld	s7,24(sp)
    80000234:	bfa5                	j	800001ac <consoleread+0x3e>
        release(&cons.lock);
    80000236:	00012517          	auipc	a0,0x12
    8000023a:	b1a50513          	add	a0,a0,-1254 # 80011d50 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	aae080e7          	jalr	-1362(ra) # 80000cec <release>
        return -1;
    80000246:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000248:	60e6                	ld	ra,88(sp)
    8000024a:	6446                	ld	s0,80(sp)
    8000024c:	64a6                	ld	s1,72(sp)
    8000024e:	6906                	ld	s2,64(sp)
    80000250:	79e2                	ld	s3,56(sp)
    80000252:	7a42                	ld	s4,48(sp)
    80000254:	7aa2                	ld	s5,40(sp)
    80000256:	7b02                	ld	s6,32(sp)
    80000258:	6125                	add	sp,sp,96
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	0009871b          	sext.w	a4,s3
    80000260:	01677a63          	bgeu	a4,s6,80000274 <consoleread+0x106>
        cons.r--;
    80000264:	00012717          	auipc	a4,0x12
    80000268:	b8f72223          	sw	a5,-1148(a4) # 80011de8 <cons+0x98>
    8000026c:	6be2                	ld	s7,24(sp)
    8000026e:	a031                	j	8000027a <consoleread+0x10c>
    80000270:	ec5e                	sd	s7,24(sp)
    80000272:	bf9d                	j	800001e8 <consoleread+0x7a>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	a011                	j	8000027a <consoleread+0x10c>
    80000278:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    8000027a:	00012517          	auipc	a0,0x12
    8000027e:	ad650513          	add	a0,a0,-1322 # 80011d50 <cons>
    80000282:	00001097          	auipc	ra,0x1
    80000286:	a6a080e7          	jalr	-1430(ra) # 80000cec <release>
  return target - n;
    8000028a:	413b053b          	subw	a0,s6,s3
    8000028e:	bf6d                	j	80000248 <consoleread+0xda>
    80000290:	6be2                	ld	s7,24(sp)
    80000292:	b7e5                	j	8000027a <consoleread+0x10c>

0000000080000294 <consputc>:
{
    80000294:	1141                	add	sp,sp,-16
    80000296:	e406                	sd	ra,8(sp)
    80000298:	e022                	sd	s0,0(sp)
    8000029a:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    8000029c:	10000793          	li	a5,256
    800002a0:	00f50a63          	beq	a0,a5,800002b4 <consputc+0x20>
    uartputc_sync(c);
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	59c080e7          	jalr	1436(ra) # 80000840 <uartputc_sync>
}
    800002ac:	60a2                	ld	ra,8(sp)
    800002ae:	6402                	ld	s0,0(sp)
    800002b0:	0141                	add	sp,sp,16
    800002b2:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	58a080e7          	jalr	1418(ra) # 80000840 <uartputc_sync>
    800002be:	02000513          	li	a0,32
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	57e080e7          	jalr	1406(ra) # 80000840 <uartputc_sync>
    800002ca:	4521                	li	a0,8
    800002cc:	00000097          	auipc	ra,0x0
    800002d0:	574080e7          	jalr	1396(ra) # 80000840 <uartputc_sync>
    800002d4:	bfe1                	j	800002ac <consputc+0x18>

00000000800002d6 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d6:	1101                	add	sp,sp,-32
    800002d8:	ec06                	sd	ra,24(sp)
    800002da:	e822                	sd	s0,16(sp)
    800002dc:	e426                	sd	s1,8(sp)
    800002de:	1000                	add	s0,sp,32
    800002e0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002e2:	00012517          	auipc	a0,0x12
    800002e6:	a6e50513          	add	a0,a0,-1426 # 80011d50 <cons>
    800002ea:	00001097          	auipc	ra,0x1
    800002ee:	94e080e7          	jalr	-1714(ra) # 80000c38 <acquire>

  switch(c){
    800002f2:	47d5                	li	a5,21
    800002f4:	0af48563          	beq	s1,a5,8000039e <consoleintr+0xc8>
    800002f8:	0297c963          	blt	a5,s1,8000032a <consoleintr+0x54>
    800002fc:	47a1                	li	a5,8
    800002fe:	0ef48c63          	beq	s1,a5,800003f6 <consoleintr+0x120>
    80000302:	47c1                	li	a5,16
    80000304:	10f49f63          	bne	s1,a5,80000422 <consoleintr+0x14c>
  case C('P'):  // Print process list.
    procdump();
    80000308:	00002097          	auipc	ra,0x2
    8000030c:	7d4080e7          	jalr	2004(ra) # 80002adc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000310:	00012517          	auipc	a0,0x12
    80000314:	a4050513          	add	a0,a0,-1472 # 80011d50 <cons>
    80000318:	00001097          	auipc	ra,0x1
    8000031c:	9d4080e7          	jalr	-1580(ra) # 80000cec <release>
}
    80000320:	60e2                	ld	ra,24(sp)
    80000322:	6442                	ld	s0,16(sp)
    80000324:	64a2                	ld	s1,8(sp)
    80000326:	6105                	add	sp,sp,32
    80000328:	8082                	ret
  switch(c){
    8000032a:	07f00793          	li	a5,127
    8000032e:	0cf48463          	beq	s1,a5,800003f6 <consoleintr+0x120>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000332:	00012717          	auipc	a4,0x12
    80000336:	a1e70713          	add	a4,a4,-1506 # 80011d50 <cons>
    8000033a:	0a072783          	lw	a5,160(a4)
    8000033e:	09872703          	lw	a4,152(a4)
    80000342:	9f99                	subw	a5,a5,a4
    80000344:	07f00713          	li	a4,127
    80000348:	fcf764e3          	bltu	a4,a5,80000310 <consoleintr+0x3a>
      c = (c == '\r') ? '\n' : c;
    8000034c:	47b5                	li	a5,13
    8000034e:	0cf48d63          	beq	s1,a5,80000428 <consoleintr+0x152>
      consputc(c);
    80000352:	8526                	mv	a0,s1
    80000354:	00000097          	auipc	ra,0x0
    80000358:	f40080e7          	jalr	-192(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000035c:	00012797          	auipc	a5,0x12
    80000360:	9f478793          	add	a5,a5,-1548 # 80011d50 <cons>
    80000364:	0a07a683          	lw	a3,160(a5)
    80000368:	0016871b          	addw	a4,a3,1
    8000036c:	0007061b          	sext.w	a2,a4
    80000370:	0ae7a023          	sw	a4,160(a5)
    80000374:	07f6f693          	and	a3,a3,127
    80000378:	97b6                	add	a5,a5,a3
    8000037a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000037e:	47a9                	li	a5,10
    80000380:	0cf48b63          	beq	s1,a5,80000456 <consoleintr+0x180>
    80000384:	4791                	li	a5,4
    80000386:	0cf48863          	beq	s1,a5,80000456 <consoleintr+0x180>
    8000038a:	00012797          	auipc	a5,0x12
    8000038e:	a5e7a783          	lw	a5,-1442(a5) # 80011de8 <cons+0x98>
    80000392:	9f1d                	subw	a4,a4,a5
    80000394:	08000793          	li	a5,128
    80000398:	f6f71ce3          	bne	a4,a5,80000310 <consoleintr+0x3a>
    8000039c:	a86d                	j	80000456 <consoleintr+0x180>
    8000039e:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    800003a0:	00012717          	auipc	a4,0x12
    800003a4:	9b070713          	add	a4,a4,-1616 # 80011d50 <cons>
    800003a8:	0a072783          	lw	a5,160(a4)
    800003ac:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003b0:	00012497          	auipc	s1,0x12
    800003b4:	9a048493          	add	s1,s1,-1632 # 80011d50 <cons>
    while(cons.e != cons.w &&
    800003b8:	4929                	li	s2,10
    800003ba:	02f70a63          	beq	a4,a5,800003ee <consoleintr+0x118>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003be:	37fd                	addw	a5,a5,-1
    800003c0:	07f7f713          	and	a4,a5,127
    800003c4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c6:	01874703          	lbu	a4,24(a4)
    800003ca:	03270463          	beq	a4,s2,800003f2 <consoleintr+0x11c>
      cons.e--;
    800003ce:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003d2:	10000513          	li	a0,256
    800003d6:	00000097          	auipc	ra,0x0
    800003da:	ebe080e7          	jalr	-322(ra) # 80000294 <consputc>
    while(cons.e != cons.w &&
    800003de:	0a04a783          	lw	a5,160(s1)
    800003e2:	09c4a703          	lw	a4,156(s1)
    800003e6:	fcf71ce3          	bne	a4,a5,800003be <consoleintr+0xe8>
    800003ea:	6902                	ld	s2,0(sp)
    800003ec:	b715                	j	80000310 <consoleintr+0x3a>
    800003ee:	6902                	ld	s2,0(sp)
    800003f0:	b705                	j	80000310 <consoleintr+0x3a>
    800003f2:	6902                	ld	s2,0(sp)
    800003f4:	bf31                	j	80000310 <consoleintr+0x3a>
    if(cons.e != cons.w){
    800003f6:	00012717          	auipc	a4,0x12
    800003fa:	95a70713          	add	a4,a4,-1702 # 80011d50 <cons>
    800003fe:	0a072783          	lw	a5,160(a4)
    80000402:	09c72703          	lw	a4,156(a4)
    80000406:	f0f705e3          	beq	a4,a5,80000310 <consoleintr+0x3a>
      cons.e--;
    8000040a:	37fd                	addw	a5,a5,-1
    8000040c:	00012717          	auipc	a4,0x12
    80000410:	9ef72223          	sw	a5,-1564(a4) # 80011df0 <cons+0xa0>
      consputc(BACKSPACE);
    80000414:	10000513          	li	a0,256
    80000418:	00000097          	auipc	ra,0x0
    8000041c:	e7c080e7          	jalr	-388(ra) # 80000294 <consputc>
    80000420:	bdc5                	j	80000310 <consoleintr+0x3a>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000422:	ee0487e3          	beqz	s1,80000310 <consoleintr+0x3a>
    80000426:	b731                	j	80000332 <consoleintr+0x5c>
      consputc(c);
    80000428:	4529                	li	a0,10
    8000042a:	00000097          	auipc	ra,0x0
    8000042e:	e6a080e7          	jalr	-406(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000432:	00012797          	auipc	a5,0x12
    80000436:	91e78793          	add	a5,a5,-1762 # 80011d50 <cons>
    8000043a:	0a07a703          	lw	a4,160(a5)
    8000043e:	0017069b          	addw	a3,a4,1
    80000442:	0006861b          	sext.w	a2,a3
    80000446:	0ad7a023          	sw	a3,160(a5)
    8000044a:	07f77713          	and	a4,a4,127
    8000044e:	97ba                	add	a5,a5,a4
    80000450:	4729                	li	a4,10
    80000452:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000456:	00012797          	auipc	a5,0x12
    8000045a:	98c7ab23          	sw	a2,-1642(a5) # 80011dec <cons+0x9c>
        wakeup(&cons.r);
    8000045e:	00012517          	auipc	a0,0x12
    80000462:	98a50513          	add	a0,a0,-1654 # 80011de8 <cons+0x98>
    80000466:	00002097          	auipc	ra,0x2
    8000046a:	21a080e7          	jalr	538(ra) # 80002680 <wakeup>
    8000046e:	b54d                	j	80000310 <consoleintr+0x3a>

0000000080000470 <consoleinit>:

void
consoleinit(void)
{
    80000470:	1141                	add	sp,sp,-16
    80000472:	e406                	sd	ra,8(sp)
    80000474:	e022                	sd	s0,0(sp)
    80000476:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000478:	00009597          	auipc	a1,0x9
    8000047c:	b8858593          	add	a1,a1,-1144 # 80009000 <etext>
    80000480:	00012517          	auipc	a0,0x12
    80000484:	8d050513          	add	a0,a0,-1840 # 80011d50 <cons>
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	720080e7          	jalr	1824(ra) # 80000ba8 <initlock>

  uartinit();
    80000490:	00000097          	auipc	ra,0x0
    80000494:	354080e7          	jalr	852(ra) # 800007e4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000498:	00023797          	auipc	a5,0x23
    8000049c:	05078793          	add	a5,a5,80 # 800234e8 <devsw>
    800004a0:	00000717          	auipc	a4,0x0
    800004a4:	cce70713          	add	a4,a4,-818 # 8000016e <consoleread>
    800004a8:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004aa:	00000717          	auipc	a4,0x0
    800004ae:	c5670713          	add	a4,a4,-938 # 80000100 <consolewrite>
    800004b2:	ef98                	sd	a4,24(a5)
}
    800004b4:	60a2                	ld	ra,8(sp)
    800004b6:	6402                	ld	s0,0(sp)
    800004b8:	0141                	add	sp,sp,16
    800004ba:	8082                	ret

00000000800004bc <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004bc:	7179                	add	sp,sp,-48
    800004be:	f406                	sd	ra,40(sp)
    800004c0:	f022                	sd	s0,32(sp)
    800004c2:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004c4:	c219                	beqz	a2,800004ca <printint+0xe>
    800004c6:	08054963          	bltz	a0,80000558 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ca:	2501                	sext.w	a0,a0
    800004cc:	4881                	li	a7,0
    800004ce:	fd040693          	add	a3,s0,-48

  i = 0;
    800004d2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004d4:	2581                	sext.w	a1,a1
    800004d6:	00009617          	auipc	a2,0x9
    800004da:	43260613          	add	a2,a2,1074 # 80009908 <digits>
    800004de:	883a                	mv	a6,a4
    800004e0:	2705                	addw	a4,a4,1
    800004e2:	02b577bb          	remuw	a5,a0,a1
    800004e6:	1782                	sll	a5,a5,0x20
    800004e8:	9381                	srl	a5,a5,0x20
    800004ea:	97b2                	add	a5,a5,a2
    800004ec:	0007c783          	lbu	a5,0(a5)
    800004f0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004f4:	0005079b          	sext.w	a5,a0
    800004f8:	02b5553b          	divuw	a0,a0,a1
    800004fc:	0685                	add	a3,a3,1
    800004fe:	feb7f0e3          	bgeu	a5,a1,800004de <printint+0x22>

  if(sign)
    80000502:	00088c63          	beqz	a7,8000051a <printint+0x5e>
    buf[i++] = '-';
    80000506:	fe070793          	add	a5,a4,-32
    8000050a:	00878733          	add	a4,a5,s0
    8000050e:	02d00793          	li	a5,45
    80000512:	fef70823          	sb	a5,-16(a4)
    80000516:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    8000051a:	02e05b63          	blez	a4,80000550 <printint+0x94>
    8000051e:	ec26                	sd	s1,24(sp)
    80000520:	e84a                	sd	s2,16(sp)
    80000522:	fd040793          	add	a5,s0,-48
    80000526:	00e784b3          	add	s1,a5,a4
    8000052a:	fff78913          	add	s2,a5,-1
    8000052e:	993a                	add	s2,s2,a4
    80000530:	377d                	addw	a4,a4,-1
    80000532:	1702                	sll	a4,a4,0x20
    80000534:	9301                	srl	a4,a4,0x20
    80000536:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000053a:	fff4c503          	lbu	a0,-1(s1)
    8000053e:	00000097          	auipc	ra,0x0
    80000542:	d56080e7          	jalr	-682(ra) # 80000294 <consputc>
  while(--i >= 0)
    80000546:	14fd                	add	s1,s1,-1
    80000548:	ff2499e3          	bne	s1,s2,8000053a <printint+0x7e>
    8000054c:	64e2                	ld	s1,24(sp)
    8000054e:	6942                	ld	s2,16(sp)
}
    80000550:	70a2                	ld	ra,40(sp)
    80000552:	7402                	ld	s0,32(sp)
    80000554:	6145                	add	sp,sp,48
    80000556:	8082                	ret
    x = -xx;
    80000558:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000055c:	4885                	li	a7,1
    x = -xx;
    8000055e:	bf85                	j	800004ce <printint+0x12>

0000000080000560 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000560:	1101                	add	sp,sp,-32
    80000562:	ec06                	sd	ra,24(sp)
    80000564:	e822                	sd	s0,16(sp)
    80000566:	e426                	sd	s1,8(sp)
    80000568:	1000                	add	s0,sp,32
    8000056a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000056c:	00012797          	auipc	a5,0x12
    80000570:	8a07a223          	sw	zero,-1884(a5) # 80011e10 <pr+0x18>
  printf("panic: ");
    80000574:	00009517          	auipc	a0,0x9
    80000578:	a9450513          	add	a0,a0,-1388 # 80009008 <etext+0x8>
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	02e080e7          	jalr	46(ra) # 800005aa <printf>
  printf(s);
    80000584:	8526                	mv	a0,s1
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	024080e7          	jalr	36(ra) # 800005aa <printf>
  printf("\n");
    8000058e:	00009517          	auipc	a0,0x9
    80000592:	a8250513          	add	a0,a0,-1406 # 80009010 <etext+0x10>
    80000596:	00000097          	auipc	ra,0x0
    8000059a:	014080e7          	jalr	20(ra) # 800005aa <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000059e:	4785                	li	a5,1
    800005a0:	00009717          	auipc	a4,0x9
    800005a4:	62f72823          	sw	a5,1584(a4) # 80009bd0 <panicked>
  for(;;)
    800005a8:	a001                	j	800005a8 <panic+0x48>

00000000800005aa <printf>:
{
    800005aa:	7131                	add	sp,sp,-192
    800005ac:	fc86                	sd	ra,120(sp)
    800005ae:	f8a2                	sd	s0,112(sp)
    800005b0:	e8d2                	sd	s4,80(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	0100                	add	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ca:	00012d17          	auipc	s10,0x12
    800005ce:	846d2d03          	lw	s10,-1978(s10) # 80011e10 <pr+0x18>
  if(locking)
    800005d2:	040d1463          	bnez	s10,8000061a <printf+0x70>
  if (fmt == 0)
    800005d6:	040a0b63          	beqz	s4,8000062c <printf+0x82>
  va_start(ap, fmt);
    800005da:	00840793          	add	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	18050b63          	beqz	a0,8000077c <printf+0x1d2>
    800005ea:	f4a6                	sd	s1,104(sp)
    800005ec:	f0ca                	sd	s2,96(sp)
    800005ee:	ecce                	sd	s3,88(sp)
    800005f0:	e4d6                	sd	s5,72(sp)
    800005f2:	e0da                	sd	s6,64(sp)
    800005f4:	fc5e                	sd	s7,56(sp)
    800005f6:	f862                	sd	s8,48(sp)
    800005f8:	f466                	sd	s9,40(sp)
    800005fa:	ec6e                	sd	s11,24(sp)
    800005fc:	4981                	li	s3,0
    if(c != '%'){
    800005fe:	02500b13          	li	s6,37
    switch(c){
    80000602:	07000b93          	li	s7,112
  consputc('x');
    80000606:	4cc1                	li	s9,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000608:	00009a97          	auipc	s5,0x9
    8000060c:	300a8a93          	add	s5,s5,768 # 80009908 <digits>
    switch(c){
    80000610:	07300c13          	li	s8,115
    80000614:	06400d93          	li	s11,100
    80000618:	a0b1                	j	80000664 <printf+0xba>
    acquire(&pr.lock);
    8000061a:	00011517          	auipc	a0,0x11
    8000061e:	7de50513          	add	a0,a0,2014 # 80011df8 <pr>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	616080e7          	jalr	1558(ra) # 80000c38 <acquire>
    8000062a:	b775                	j	800005d6 <printf+0x2c>
    8000062c:	f4a6                	sd	s1,104(sp)
    8000062e:	f0ca                	sd	s2,96(sp)
    80000630:	ecce                	sd	s3,88(sp)
    80000632:	e4d6                	sd	s5,72(sp)
    80000634:	e0da                	sd	s6,64(sp)
    80000636:	fc5e                	sd	s7,56(sp)
    80000638:	f862                	sd	s8,48(sp)
    8000063a:	f466                	sd	s9,40(sp)
    8000063c:	ec6e                	sd	s11,24(sp)
    panic("null fmt");
    8000063e:	00009517          	auipc	a0,0x9
    80000642:	9e250513          	add	a0,a0,-1566 # 80009020 <etext+0x20>
    80000646:	00000097          	auipc	ra,0x0
    8000064a:	f1a080e7          	jalr	-230(ra) # 80000560 <panic>
      consputc(c);
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	c46080e7          	jalr	-954(ra) # 80000294 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000656:	2985                	addw	s3,s3,1
    80000658:	013a07b3          	add	a5,s4,s3
    8000065c:	0007c503          	lbu	a0,0(a5)
    80000660:	10050563          	beqz	a0,8000076a <printf+0x1c0>
    if(c != '%'){
    80000664:	ff6515e3          	bne	a0,s6,8000064e <printf+0xa4>
    c = fmt[++i] & 0xff;
    80000668:	2985                	addw	s3,s3,1
    8000066a:	013a07b3          	add	a5,s4,s3
    8000066e:	0007c783          	lbu	a5,0(a5)
    80000672:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000676:	10078b63          	beqz	a5,8000078c <printf+0x1e2>
    switch(c){
    8000067a:	05778a63          	beq	a5,s7,800006ce <printf+0x124>
    8000067e:	02fbf663          	bgeu	s7,a5,800006aa <printf+0x100>
    80000682:	09878863          	beq	a5,s8,80000712 <printf+0x168>
    80000686:	07800713          	li	a4,120
    8000068a:	0ce79563          	bne	a5,a4,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 16, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	add	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	85e6                	mv	a1,s9
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e1c080e7          	jalr	-484(ra) # 800004bc <printint>
      break;
    800006a8:	b77d                	j	80000656 <printf+0xac>
    switch(c){
    800006aa:	09678f63          	beq	a5,s6,80000748 <printf+0x19e>
    800006ae:	0bb79363          	bne	a5,s11,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 10, 1);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	add	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4605                	li	a2,1
    800006c0:	45a9                	li	a1,10
    800006c2:	4388                	lw	a0,0(a5)
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	df8080e7          	jalr	-520(ra) # 800004bc <printint>
      break;
    800006cc:	b769                	j	80000656 <printf+0xac>
      printptr(va_arg(ap, uint64));
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	add	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006de:	03000513          	li	a0,48
    800006e2:	00000097          	auipc	ra,0x0
    800006e6:	bb2080e7          	jalr	-1102(ra) # 80000294 <consputc>
  consputc('x');
    800006ea:	07800513          	li	a0,120
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	ba6080e7          	jalr	-1114(ra) # 80000294 <consputc>
    800006f6:	84e6                	mv	s1,s9
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006f8:	03c95793          	srl	a5,s2,0x3c
    800006fc:	97d6                	add	a5,a5,s5
    800006fe:	0007c503          	lbu	a0,0(a5)
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b92080e7          	jalr	-1134(ra) # 80000294 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000070a:	0912                	sll	s2,s2,0x4
    8000070c:	34fd                	addw	s1,s1,-1
    8000070e:	f4ed                	bnez	s1,800006f8 <printf+0x14e>
    80000710:	b799                	j	80000656 <printf+0xac>
      if((s = va_arg(ap, char*)) == 0)
    80000712:	f8843783          	ld	a5,-120(s0)
    80000716:	00878713          	add	a4,a5,8
    8000071a:	f8e43423          	sd	a4,-120(s0)
    8000071e:	6384                	ld	s1,0(a5)
    80000720:	cc89                	beqz	s1,8000073a <printf+0x190>
      for(; *s; s++)
    80000722:	0004c503          	lbu	a0,0(s1)
    80000726:	d905                	beqz	a0,80000656 <printf+0xac>
        consputc(*s);
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b6c080e7          	jalr	-1172(ra) # 80000294 <consputc>
      for(; *s; s++)
    80000730:	0485                	add	s1,s1,1
    80000732:	0004c503          	lbu	a0,0(s1)
    80000736:	f96d                	bnez	a0,80000728 <printf+0x17e>
    80000738:	bf39                	j	80000656 <printf+0xac>
        s = "(null)";
    8000073a:	00009497          	auipc	s1,0x9
    8000073e:	8de48493          	add	s1,s1,-1826 # 80009018 <etext+0x18>
      for(; *s; s++)
    80000742:	02800513          	li	a0,40
    80000746:	b7cd                	j	80000728 <printf+0x17e>
      consputc('%');
    80000748:	855a                	mv	a0,s6
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	b4a080e7          	jalr	-1206(ra) # 80000294 <consputc>
      break;
    80000752:	b711                	j	80000656 <printf+0xac>
      consputc('%');
    80000754:	855a                	mv	a0,s6
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	b3e080e7          	jalr	-1218(ra) # 80000294 <consputc>
      consputc(c);
    8000075e:	8526                	mv	a0,s1
    80000760:	00000097          	auipc	ra,0x0
    80000764:	b34080e7          	jalr	-1228(ra) # 80000294 <consputc>
      break;
    80000768:	b5fd                	j	80000656 <printf+0xac>
    8000076a:	74a6                	ld	s1,104(sp)
    8000076c:	7906                	ld	s2,96(sp)
    8000076e:	69e6                	ld	s3,88(sp)
    80000770:	6aa6                	ld	s5,72(sp)
    80000772:	6b06                	ld	s6,64(sp)
    80000774:	7be2                	ld	s7,56(sp)
    80000776:	7c42                	ld	s8,48(sp)
    80000778:	7ca2                	ld	s9,40(sp)
    8000077a:	6de2                	ld	s11,24(sp)
  if(locking)
    8000077c:	020d1263          	bnez	s10,800007a0 <printf+0x1f6>
}
    80000780:	70e6                	ld	ra,120(sp)
    80000782:	7446                	ld	s0,112(sp)
    80000784:	6a46                	ld	s4,80(sp)
    80000786:	7d02                	ld	s10,32(sp)
    80000788:	6129                	add	sp,sp,192
    8000078a:	8082                	ret
    8000078c:	74a6                	ld	s1,104(sp)
    8000078e:	7906                	ld	s2,96(sp)
    80000790:	69e6                	ld	s3,88(sp)
    80000792:	6aa6                	ld	s5,72(sp)
    80000794:	6b06                	ld	s6,64(sp)
    80000796:	7be2                	ld	s7,56(sp)
    80000798:	7c42                	ld	s8,48(sp)
    8000079a:	7ca2                	ld	s9,40(sp)
    8000079c:	6de2                	ld	s11,24(sp)
    8000079e:	bff9                	j	8000077c <printf+0x1d2>
    release(&pr.lock);
    800007a0:	00011517          	auipc	a0,0x11
    800007a4:	65850513          	add	a0,a0,1624 # 80011df8 <pr>
    800007a8:	00000097          	auipc	ra,0x0
    800007ac:	544080e7          	jalr	1348(ra) # 80000cec <release>
}
    800007b0:	bfc1                	j	80000780 <printf+0x1d6>

00000000800007b2 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007b2:	1101                	add	sp,sp,-32
    800007b4:	ec06                	sd	ra,24(sp)
    800007b6:	e822                	sd	s0,16(sp)
    800007b8:	e426                	sd	s1,8(sp)
    800007ba:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    800007bc:	00011497          	auipc	s1,0x11
    800007c0:	63c48493          	add	s1,s1,1596 # 80011df8 <pr>
    800007c4:	00009597          	auipc	a1,0x9
    800007c8:	86c58593          	add	a1,a1,-1940 # 80009030 <etext+0x30>
    800007cc:	8526                	mv	a0,s1
    800007ce:	00000097          	auipc	ra,0x0
    800007d2:	3da080e7          	jalr	986(ra) # 80000ba8 <initlock>
  pr.locking = 1;
    800007d6:	4785                	li	a5,1
    800007d8:	cc9c                	sw	a5,24(s1)
}
    800007da:	60e2                	ld	ra,24(sp)
    800007dc:	6442                	ld	s0,16(sp)
    800007de:	64a2                	ld	s1,8(sp)
    800007e0:	6105                	add	sp,sp,32
    800007e2:	8082                	ret

00000000800007e4 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007e4:	1141                	add	sp,sp,-16
    800007e6:	e406                	sd	ra,8(sp)
    800007e8:	e022                	sd	s0,0(sp)
    800007ea:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ec:	100007b7          	lui	a5,0x10000
    800007f0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007f4:	10000737          	lui	a4,0x10000
    800007f8:	f8000693          	li	a3,-128
    800007fc:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000800:	468d                	li	a3,3
    80000802:	10000637          	lui	a2,0x10000
    80000806:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000080a:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000080e:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000812:	10000737          	lui	a4,0x10000
    80000816:	461d                	li	a2,7
    80000818:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000081c:	00d780a3          	sb	a3,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000820:	00009597          	auipc	a1,0x9
    80000824:	81858593          	add	a1,a1,-2024 # 80009038 <etext+0x38>
    80000828:	00011517          	auipc	a0,0x11
    8000082c:	5f050513          	add	a0,a0,1520 # 80011e18 <uart_tx_lock>
    80000830:	00000097          	auipc	ra,0x0
    80000834:	378080e7          	jalr	888(ra) # 80000ba8 <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	add	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000840:	1101                	add	sp,sp,-32
    80000842:	ec06                	sd	ra,24(sp)
    80000844:	e822                	sd	s0,16(sp)
    80000846:	e426                	sd	s1,8(sp)
    80000848:	1000                	add	s0,sp,32
    8000084a:	84aa                	mv	s1,a0
  push_off();
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	3a0080e7          	jalr	928(ra) # 80000bec <push_off>

  if(panicked){
    80000854:	00009797          	auipc	a5,0x9
    80000858:	37c7a783          	lw	a5,892(a5) # 80009bd0 <panicked>
    8000085c:	eb85                	bnez	a5,8000088c <uartputc_sync+0x4c>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000085e:	10000737          	lui	a4,0x10000
    80000862:	0715                	add	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000864:	00074783          	lbu	a5,0(a4)
    80000868:	0207f793          	and	a5,a5,32
    8000086c:	dfe5                	beqz	a5,80000864 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000086e:	0ff4f513          	zext.b	a0,s1
    80000872:	100007b7          	lui	a5,0x10000
    80000876:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	412080e7          	jalr	1042(ra) # 80000c8c <pop_off>
}
    80000882:	60e2                	ld	ra,24(sp)
    80000884:	6442                	ld	s0,16(sp)
    80000886:	64a2                	ld	s1,8(sp)
    80000888:	6105                	add	sp,sp,32
    8000088a:	8082                	ret
    for(;;)
    8000088c:	a001                	j	8000088c <uartputc_sync+0x4c>

000000008000088e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000088e:	00009797          	auipc	a5,0x9
    80000892:	34a7b783          	ld	a5,842(a5) # 80009bd8 <uart_tx_r>
    80000896:	00009717          	auipc	a4,0x9
    8000089a:	34a73703          	ld	a4,842(a4) # 80009be0 <uart_tx_w>
    8000089e:	06f70f63          	beq	a4,a5,8000091c <uartstart+0x8e>
{
    800008a2:	7139                	add	sp,sp,-64
    800008a4:	fc06                	sd	ra,56(sp)
    800008a6:	f822                	sd	s0,48(sp)
    800008a8:	f426                	sd	s1,40(sp)
    800008aa:	f04a                	sd	s2,32(sp)
    800008ac:	ec4e                	sd	s3,24(sp)
    800008ae:	e852                	sd	s4,16(sp)
    800008b0:	e456                	sd	s5,8(sp)
    800008b2:	e05a                	sd	s6,0(sp)
    800008b4:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008b6:	10000937          	lui	s2,0x10000
    800008ba:	0915                	add	s2,s2,5 # 10000005 <_entry-0x6ffffffb>
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008bc:	00011a97          	auipc	s5,0x11
    800008c0:	55ca8a93          	add	s5,s5,1372 # 80011e18 <uart_tx_lock>
    uart_tx_r += 1;
    800008c4:	00009497          	auipc	s1,0x9
    800008c8:	31448493          	add	s1,s1,788 # 80009bd8 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008cc:	10000a37          	lui	s4,0x10000
    if(uart_tx_w == uart_tx_r){
    800008d0:	00009997          	auipc	s3,0x9
    800008d4:	31098993          	add	s3,s3,784 # 80009be0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d8:	00094703          	lbu	a4,0(s2)
    800008dc:	02077713          	and	a4,a4,32
    800008e0:	c705                	beqz	a4,80000908 <uartstart+0x7a>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008e2:	01f7f713          	and	a4,a5,31
    800008e6:	9756                	add	a4,a4,s5
    800008e8:	01874b03          	lbu	s6,24(a4)
    uart_tx_r += 1;
    800008ec:	0785                	add	a5,a5,1
    800008ee:	e09c                	sd	a5,0(s1)
    wakeup(&uart_tx_r);
    800008f0:	8526                	mv	a0,s1
    800008f2:	00002097          	auipc	ra,0x2
    800008f6:	d8e080e7          	jalr	-626(ra) # 80002680 <wakeup>
    WriteReg(THR, c);
    800008fa:	016a0023          	sb	s6,0(s4) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008fe:	609c                	ld	a5,0(s1)
    80000900:	0009b703          	ld	a4,0(s3)
    80000904:	fcf71ae3          	bne	a4,a5,800008d8 <uartstart+0x4a>
  }
}
    80000908:	70e2                	ld	ra,56(sp)
    8000090a:	7442                	ld	s0,48(sp)
    8000090c:	74a2                	ld	s1,40(sp)
    8000090e:	7902                	ld	s2,32(sp)
    80000910:	69e2                	ld	s3,24(sp)
    80000912:	6a42                	ld	s4,16(sp)
    80000914:	6aa2                	ld	s5,8(sp)
    80000916:	6b02                	ld	s6,0(sp)
    80000918:	6121                	add	sp,sp,64
    8000091a:	8082                	ret
    8000091c:	8082                	ret

000000008000091e <uartputc>:
{
    8000091e:	7179                	add	sp,sp,-48
    80000920:	f406                	sd	ra,40(sp)
    80000922:	f022                	sd	s0,32(sp)
    80000924:	ec26                	sd	s1,24(sp)
    80000926:	e84a                	sd	s2,16(sp)
    80000928:	e44e                	sd	s3,8(sp)
    8000092a:	e052                	sd	s4,0(sp)
    8000092c:	1800                	add	s0,sp,48
    8000092e:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000930:	00011517          	auipc	a0,0x11
    80000934:	4e850513          	add	a0,a0,1256 # 80011e18 <uart_tx_lock>
    80000938:	00000097          	auipc	ra,0x0
    8000093c:	300080e7          	jalr	768(ra) # 80000c38 <acquire>
  if(panicked){
    80000940:	00009797          	auipc	a5,0x9
    80000944:	2907a783          	lw	a5,656(a5) # 80009bd0 <panicked>
    80000948:	e7c9                	bnez	a5,800009d2 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	00009717          	auipc	a4,0x9
    8000094e:	29673703          	ld	a4,662(a4) # 80009be0 <uart_tx_w>
    80000952:	00009797          	auipc	a5,0x9
    80000956:	2867b783          	ld	a5,646(a5) # 80009bd8 <uart_tx_r>
    8000095a:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000095e:	00011997          	auipc	s3,0x11
    80000962:	4ba98993          	add	s3,s3,1210 # 80011e18 <uart_tx_lock>
    80000966:	00009497          	auipc	s1,0x9
    8000096a:	27248493          	add	s1,s1,626 # 80009bd8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000096e:	00009917          	auipc	s2,0x9
    80000972:	27290913          	add	s2,s2,626 # 80009be0 <uart_tx_w>
    80000976:	00e79f63          	bne	a5,a4,80000994 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000097a:	85ce                	mv	a1,s3
    8000097c:	8526                	mv	a0,s1
    8000097e:	00002097          	auipc	ra,0x2
    80000982:	b52080e7          	jalr	-1198(ra) # 800024d0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000986:	00093703          	ld	a4,0(s2)
    8000098a:	609c                	ld	a5,0(s1)
    8000098c:	02078793          	add	a5,a5,32
    80000990:	fee785e3          	beq	a5,a4,8000097a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000994:	00011497          	auipc	s1,0x11
    80000998:	48448493          	add	s1,s1,1156 # 80011e18 <uart_tx_lock>
    8000099c:	01f77793          	and	a5,a4,31
    800009a0:	97a6                	add	a5,a5,s1
    800009a2:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009a6:	0705                	add	a4,a4,1
    800009a8:	00009797          	auipc	a5,0x9
    800009ac:	22e7bc23          	sd	a4,568(a5) # 80009be0 <uart_tx_w>
  uartstart();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	ede080e7          	jalr	-290(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    800009b8:	8526                	mv	a0,s1
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	332080e7          	jalr	818(ra) # 80000cec <release>
}
    800009c2:	70a2                	ld	ra,40(sp)
    800009c4:	7402                	ld	s0,32(sp)
    800009c6:	64e2                	ld	s1,24(sp)
    800009c8:	6942                	ld	s2,16(sp)
    800009ca:	69a2                	ld	s3,8(sp)
    800009cc:	6a02                	ld	s4,0(sp)
    800009ce:	6145                	add	sp,sp,48
    800009d0:	8082                	ret
    for(;;)
    800009d2:	a001                	j	800009d2 <uartputc+0xb4>

00000000800009d4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009d4:	1141                	add	sp,sp,-16
    800009d6:	e422                	sd	s0,8(sp)
    800009d8:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009da:	100007b7          	lui	a5,0x10000
    800009de:	0795                	add	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009e0:	0007c783          	lbu	a5,0(a5)
    800009e4:	8b85                	and	a5,a5,1
    800009e6:	cb81                	beqz	a5,800009f6 <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    800009e8:	100007b7          	lui	a5,0x10000
    800009ec:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009f0:	6422                	ld	s0,8(sp)
    800009f2:	0141                	add	sp,sp,16
    800009f4:	8082                	ret
    return -1;
    800009f6:	557d                	li	a0,-1
    800009f8:	bfe5                	j	800009f0 <uartgetc+0x1c>

00000000800009fa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009fa:	1101                	add	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a04:	54fd                	li	s1,-1
    80000a06:	a029                	j	80000a10 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	8ce080e7          	jalr	-1842(ra) # 800002d6 <consoleintr>
    int c = uartgetc();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	fc4080e7          	jalr	-60(ra) # 800009d4 <uartgetc>
    if(c == -1)
    80000a18:	fe9518e3          	bne	a0,s1,80000a08 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a1c:	00011497          	auipc	s1,0x11
    80000a20:	3fc48493          	add	s1,s1,1020 # 80011e18 <uart_tx_lock>
    80000a24:	8526                	mv	a0,s1
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	212080e7          	jalr	530(ra) # 80000c38 <acquire>
  uartstart();
    80000a2e:	00000097          	auipc	ra,0x0
    80000a32:	e60080e7          	jalr	-416(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    80000a36:	8526                	mv	a0,s1
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	2b4080e7          	jalr	692(ra) # 80000cec <release>
}
    80000a40:	60e2                	ld	ra,24(sp)
    80000a42:	6442                	ld	s0,16(sp)
    80000a44:	64a2                	ld	s1,8(sp)
    80000a46:	6105                	add	sp,sp,32
    80000a48:	8082                	ret

0000000080000a4a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a4a:	1101                	add	sp,sp,-32
    80000a4c:	ec06                	sd	ra,24(sp)
    80000a4e:	e822                	sd	s0,16(sp)
    80000a50:	e426                	sd	s1,8(sp)
    80000a52:	e04a                	sd	s2,0(sp)
    80000a54:	1000                	add	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a56:	03451793          	sll	a5,a0,0x34
    80000a5a:	ebb9                	bnez	a5,80000ab0 <kfree+0x66>
    80000a5c:	84aa                	mv	s1,a0
    80000a5e:	00024797          	auipc	a5,0x24
    80000a62:	64a78793          	add	a5,a5,1610 # 800250a8 <end>
    80000a66:	04f56563          	bltu	a0,a5,80000ab0 <kfree+0x66>
    80000a6a:	47c5                	li	a5,17
    80000a6c:	07ee                	sll	a5,a5,0x1b
    80000a6e:	04f57163          	bgeu	a0,a5,80000ab0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a72:	6605                	lui	a2,0x1
    80000a74:	4585                	li	a1,1
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	2be080e7          	jalr	702(ra) # 80000d34 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a7e:	00011917          	auipc	s2,0x11
    80000a82:	3d290913          	add	s2,s2,978 # 80011e50 <kmem>
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	1b0080e7          	jalr	432(ra) # 80000c38 <acquire>
  r->next = kmem.freelist;
    80000a90:	01893783          	ld	a5,24(s2)
    80000a94:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a96:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9a:	854a                	mv	a0,s2
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	250080e7          	jalr	592(ra) # 80000cec <release>
}
    80000aa4:	60e2                	ld	ra,24(sp)
    80000aa6:	6442                	ld	s0,16(sp)
    80000aa8:	64a2                	ld	s1,8(sp)
    80000aaa:	6902                	ld	s2,0(sp)
    80000aac:	6105                	add	sp,sp,32
    80000aae:	8082                	ret
    panic("kfree");
    80000ab0:	00008517          	auipc	a0,0x8
    80000ab4:	59050513          	add	a0,a0,1424 # 80009040 <etext+0x40>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	aa8080e7          	jalr	-1368(ra) # 80000560 <panic>

0000000080000ac0 <freerange>:
{
    80000ac0:	7179                	add	sp,sp,-48
    80000ac2:	f406                	sd	ra,40(sp)
    80000ac4:	f022                	sd	s0,32(sp)
    80000ac6:	ec26                	sd	s1,24(sp)
    80000ac8:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aca:	6785                	lui	a5,0x1
    80000acc:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad0:	00e504b3          	add	s1,a0,a4
    80000ad4:	777d                	lui	a4,0xfffff
    80000ad6:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad8:	94be                	add	s1,s1,a5
    80000ada:	0295e463          	bltu	a1,s1,80000b02 <freerange+0x42>
    80000ade:	e84a                	sd	s2,16(sp)
    80000ae0:	e44e                	sd	s3,8(sp)
    80000ae2:	e052                	sd	s4,0(sp)
    80000ae4:	892e                	mv	s2,a1
    kfree(p);
    80000ae6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae8:	6985                	lui	s3,0x1
    kfree(p);
    80000aea:	01448533          	add	a0,s1,s4
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	f5c080e7          	jalr	-164(ra) # 80000a4a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af6:	94ce                	add	s1,s1,s3
    80000af8:	fe9979e3          	bgeu	s2,s1,80000aea <freerange+0x2a>
    80000afc:	6942                	ld	s2,16(sp)
    80000afe:	69a2                	ld	s3,8(sp)
    80000b00:	6a02                	ld	s4,0(sp)
}
    80000b02:	70a2                	ld	ra,40(sp)
    80000b04:	7402                	ld	s0,32(sp)
    80000b06:	64e2                	ld	s1,24(sp)
    80000b08:	6145                	add	sp,sp,48
    80000b0a:	8082                	ret

0000000080000b0c <kinit>:
{
    80000b0c:	1141                	add	sp,sp,-16
    80000b0e:	e406                	sd	ra,8(sp)
    80000b10:	e022                	sd	s0,0(sp)
    80000b12:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b14:	00008597          	auipc	a1,0x8
    80000b18:	53458593          	add	a1,a1,1332 # 80009048 <etext+0x48>
    80000b1c:	00011517          	auipc	a0,0x11
    80000b20:	33450513          	add	a0,a0,820 # 80011e50 <kmem>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	084080e7          	jalr	132(ra) # 80000ba8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b2c:	45c5                	li	a1,17
    80000b2e:	05ee                	sll	a1,a1,0x1b
    80000b30:	00024517          	auipc	a0,0x24
    80000b34:	57850513          	add	a0,a0,1400 # 800250a8 <end>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	f88080e7          	jalr	-120(ra) # 80000ac0 <freerange>
}
    80000b40:	60a2                	ld	ra,8(sp)
    80000b42:	6402                	ld	s0,0(sp)
    80000b44:	0141                	add	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b48:	1101                	add	sp,sp,-32
    80000b4a:	ec06                	sd	ra,24(sp)
    80000b4c:	e822                	sd	s0,16(sp)
    80000b4e:	e426                	sd	s1,8(sp)
    80000b50:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b52:	00011497          	auipc	s1,0x11
    80000b56:	2fe48493          	add	s1,s1,766 # 80011e50 <kmem>
    80000b5a:	8526                	mv	a0,s1
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	0dc080e7          	jalr	220(ra) # 80000c38 <acquire>
  r = kmem.freelist;
    80000b64:	6c84                	ld	s1,24(s1)
  if(r)
    80000b66:	c885                	beqz	s1,80000b96 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b68:	609c                	ld	a5,0(s1)
    80000b6a:	00011517          	auipc	a0,0x11
    80000b6e:	2e650513          	add	a0,a0,742 # 80011e50 <kmem>
    80000b72:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b74:	00000097          	auipc	ra,0x0
    80000b78:	178080e7          	jalr	376(ra) # 80000cec <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b7c:	6605                	lui	a2,0x1
    80000b7e:	4595                	li	a1,5
    80000b80:	8526                	mv	a0,s1
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	1b2080e7          	jalr	434(ra) # 80000d34 <memset>
  return (void*)r;
}
    80000b8a:	8526                	mv	a0,s1
    80000b8c:	60e2                	ld	ra,24(sp)
    80000b8e:	6442                	ld	s0,16(sp)
    80000b90:	64a2                	ld	s1,8(sp)
    80000b92:	6105                	add	sp,sp,32
    80000b94:	8082                	ret
  release(&kmem.lock);
    80000b96:	00011517          	auipc	a0,0x11
    80000b9a:	2ba50513          	add	a0,a0,698 # 80011e50 <kmem>
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	14e080e7          	jalr	334(ra) # 80000cec <release>
  if(r)
    80000ba6:	b7d5                	j	80000b8a <kalloc+0x42>

0000000080000ba8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ba8:	1141                	add	sp,sp,-16
    80000baa:	e422                	sd	s0,8(sp)
    80000bac:	0800                	add	s0,sp,16
  lk->name = name;
    80000bae:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bb0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bb4:	00053823          	sd	zero,16(a0)
}
    80000bb8:	6422                	ld	s0,8(sp)
    80000bba:	0141                	add	sp,sp,16
    80000bbc:	8082                	ret

0000000080000bbe <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bbe:	411c                	lw	a5,0(a0)
    80000bc0:	e399                	bnez	a5,80000bc6 <holding+0x8>
    80000bc2:	4501                	li	a0,0
  return r;
}
    80000bc4:	8082                	ret
{
    80000bc6:	1101                	add	sp,sp,-32
    80000bc8:	ec06                	sd	ra,24(sp)
    80000bca:	e822                	sd	s0,16(sp)
    80000bcc:	e426                	sd	s1,8(sp)
    80000bce:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bd0:	6904                	ld	s1,16(a0)
    80000bd2:	00001097          	auipc	ra,0x1
    80000bd6:	f9c080e7          	jalr	-100(ra) # 80001b6e <mycpu>
    80000bda:	40a48533          	sub	a0,s1,a0
    80000bde:	00153513          	seqz	a0,a0
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	add	sp,sp,32
    80000bea:	8082                	ret

0000000080000bec <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bec:	1101                	add	sp,sp,-32
    80000bee:	ec06                	sd	ra,24(sp)
    80000bf0:	e822                	sd	s0,16(sp)
    80000bf2:	e426                	sd	s1,8(sp)
    80000bf4:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf6:	100024f3          	csrr	s1,sstatus
    80000bfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bfe:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c00:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c04:	00001097          	auipc	ra,0x1
    80000c08:	f6a080e7          	jalr	-150(ra) # 80001b6e <mycpu>
    80000c0c:	5d3c                	lw	a5,120(a0)
    80000c0e:	cf89                	beqz	a5,80000c28 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c10:	00001097          	auipc	ra,0x1
    80000c14:	f5e080e7          	jalr	-162(ra) # 80001b6e <mycpu>
    80000c18:	5d3c                	lw	a5,120(a0)
    80000c1a:	2785                	addw	a5,a5,1
    80000c1c:	dd3c                	sw	a5,120(a0)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	add	sp,sp,32
    80000c26:	8082                	ret
    mycpu()->intena = old;
    80000c28:	00001097          	auipc	ra,0x1
    80000c2c:	f46080e7          	jalr	-186(ra) # 80001b6e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c30:	8085                	srl	s1,s1,0x1
    80000c32:	8885                	and	s1,s1,1
    80000c34:	dd64                	sw	s1,124(a0)
    80000c36:	bfe9                	j	80000c10 <push_off+0x24>

0000000080000c38 <acquire>:
{
    80000c38:	1101                	add	sp,sp,-32
    80000c3a:	ec06                	sd	ra,24(sp)
    80000c3c:	e822                	sd	s0,16(sp)
    80000c3e:	e426                	sd	s1,8(sp)
    80000c40:	1000                	add	s0,sp,32
    80000c42:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	fa8080e7          	jalr	-88(ra) # 80000bec <push_off>
  if(holding(lk))
    80000c4c:	8526                	mv	a0,s1
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	f70080e7          	jalr	-144(ra) # 80000bbe <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c56:	4705                	li	a4,1
  if(holding(lk))
    80000c58:	e115                	bnez	a0,80000c7c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c5a:	87ba                	mv	a5,a4
    80000c5c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c60:	2781                	sext.w	a5,a5
    80000c62:	ffe5                	bnez	a5,80000c5a <acquire+0x22>
  __sync_synchronize();
    80000c64:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c68:	00001097          	auipc	ra,0x1
    80000c6c:	f06080e7          	jalr	-250(ra) # 80001b6e <mycpu>
    80000c70:	e888                	sd	a0,16(s1)
}
    80000c72:	60e2                	ld	ra,24(sp)
    80000c74:	6442                	ld	s0,16(sp)
    80000c76:	64a2                	ld	s1,8(sp)
    80000c78:	6105                	add	sp,sp,32
    80000c7a:	8082                	ret
    panic("acquire");
    80000c7c:	00008517          	auipc	a0,0x8
    80000c80:	3d450513          	add	a0,a0,980 # 80009050 <etext+0x50>
    80000c84:	00000097          	auipc	ra,0x0
    80000c88:	8dc080e7          	jalr	-1828(ra) # 80000560 <panic>

0000000080000c8c <pop_off>:

void
pop_off(void)
{
    80000c8c:	1141                	add	sp,sp,-16
    80000c8e:	e406                	sd	ra,8(sp)
    80000c90:	e022                	sd	s0,0(sp)
    80000c92:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000c94:	00001097          	auipc	ra,0x1
    80000c98:	eda080e7          	jalr	-294(ra) # 80001b6e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ca0:	8b89                	and	a5,a5,2
  if(intr_get())
    80000ca2:	e78d                	bnez	a5,80000ccc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ca4:	5d3c                	lw	a5,120(a0)
    80000ca6:	02f05b63          	blez	a5,80000cdc <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000caa:	37fd                	addw	a5,a5,-1
    80000cac:	0007871b          	sext.w	a4,a5
    80000cb0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cb2:	eb09                	bnez	a4,80000cc4 <pop_off+0x38>
    80000cb4:	5d7c                	lw	a5,124(a0)
    80000cb6:	c799                	beqz	a5,80000cc4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cbc:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cc4:	60a2                	ld	ra,8(sp)
    80000cc6:	6402                	ld	s0,0(sp)
    80000cc8:	0141                	add	sp,sp,16
    80000cca:	8082                	ret
    panic("pop_off - interruptible");
    80000ccc:	00008517          	auipc	a0,0x8
    80000cd0:	38c50513          	add	a0,a0,908 # 80009058 <etext+0x58>
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	88c080e7          	jalr	-1908(ra) # 80000560 <panic>
    panic("pop_off");
    80000cdc:	00008517          	auipc	a0,0x8
    80000ce0:	39450513          	add	a0,a0,916 # 80009070 <etext+0x70>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	87c080e7          	jalr	-1924(ra) # 80000560 <panic>

0000000080000cec <release>:
{
    80000cec:	1101                	add	sp,sp,-32
    80000cee:	ec06                	sd	ra,24(sp)
    80000cf0:	e822                	sd	s0,16(sp)
    80000cf2:	e426                	sd	s1,8(sp)
    80000cf4:	1000                	add	s0,sp,32
    80000cf6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	ec6080e7          	jalr	-314(ra) # 80000bbe <holding>
    80000d00:	c115                	beqz	a0,80000d24 <release+0x38>
  lk->cpu = 0;
    80000d02:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d06:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d0a:	0f50000f          	fence	iorw,ow
    80000d0e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	f7a080e7          	jalr	-134(ra) # 80000c8c <pop_off>
}
    80000d1a:	60e2                	ld	ra,24(sp)
    80000d1c:	6442                	ld	s0,16(sp)
    80000d1e:	64a2                	ld	s1,8(sp)
    80000d20:	6105                	add	sp,sp,32
    80000d22:	8082                	ret
    panic("release");
    80000d24:	00008517          	auipc	a0,0x8
    80000d28:	35450513          	add	a0,a0,852 # 80009078 <etext+0x78>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	834080e7          	jalr	-1996(ra) # 80000560 <panic>

0000000080000d34 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d34:	1141                	add	sp,sp,-16
    80000d36:	e422                	sd	s0,8(sp)
    80000d38:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d3a:	ca19                	beqz	a2,80000d50 <memset+0x1c>
    80000d3c:	87aa                	mv	a5,a0
    80000d3e:	1602                	sll	a2,a2,0x20
    80000d40:	9201                	srl	a2,a2,0x20
    80000d42:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d46:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d4a:	0785                	add	a5,a5,1
    80000d4c:	fee79de3          	bne	a5,a4,80000d46 <memset+0x12>
  }
  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	add	sp,sp,16
    80000d54:	8082                	ret

0000000080000d56 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d56:	1141                	add	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d5c:	ca05                	beqz	a2,80000d8c <memcmp+0x36>
    80000d5e:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d62:	1682                	sll	a3,a3,0x20
    80000d64:	9281                	srl	a3,a3,0x20
    80000d66:	0685                	add	a3,a3,1
    80000d68:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d6a:	00054783          	lbu	a5,0(a0)
    80000d6e:	0005c703          	lbu	a4,0(a1)
    80000d72:	00e79863          	bne	a5,a4,80000d82 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d76:	0505                	add	a0,a0,1
    80000d78:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d7a:	fed518e3          	bne	a0,a3,80000d6a <memcmp+0x14>
  }

  return 0;
    80000d7e:	4501                	li	a0,0
    80000d80:	a019                	j	80000d86 <memcmp+0x30>
      return *s1 - *s2;
    80000d82:	40e7853b          	subw	a0,a5,a4
}
    80000d86:	6422                	ld	s0,8(sp)
    80000d88:	0141                	add	sp,sp,16
    80000d8a:	8082                	ret
  return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	bfe5                	j	80000d86 <memcmp+0x30>

0000000080000d90 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d90:	1141                	add	sp,sp,-16
    80000d92:	e422                	sd	s0,8(sp)
    80000d94:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d96:	c205                	beqz	a2,80000db6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d98:	02a5e263          	bltu	a1,a0,80000dbc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d9c:	1602                	sll	a2,a2,0x20
    80000d9e:	9201                	srl	a2,a2,0x20
    80000da0:	00c587b3          	add	a5,a1,a2
{
    80000da4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000da6:	0585                	add	a1,a1,1
    80000da8:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd9f59>
    80000daa:	fff5c683          	lbu	a3,-1(a1)
    80000dae:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000db2:	feb79ae3          	bne	a5,a1,80000da6 <memmove+0x16>

  return dst;
}
    80000db6:	6422                	ld	s0,8(sp)
    80000db8:	0141                	add	sp,sp,16
    80000dba:	8082                	ret
  if(s < d && s + n > d){
    80000dbc:	02061693          	sll	a3,a2,0x20
    80000dc0:	9281                	srl	a3,a3,0x20
    80000dc2:	00d58733          	add	a4,a1,a3
    80000dc6:	fce57be3          	bgeu	a0,a4,80000d9c <memmove+0xc>
    d += n;
    80000dca:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dcc:	fff6079b          	addw	a5,a2,-1
    80000dd0:	1782                	sll	a5,a5,0x20
    80000dd2:	9381                	srl	a5,a5,0x20
    80000dd4:	fff7c793          	not	a5,a5
    80000dd8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dda:	177d                	add	a4,a4,-1
    80000ddc:	16fd                	add	a3,a3,-1
    80000dde:	00074603          	lbu	a2,0(a4)
    80000de2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000de6:	fef71ae3          	bne	a4,a5,80000dda <memmove+0x4a>
    80000dea:	b7f1                	j	80000db6 <memmove+0x26>

0000000080000dec <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dec:	1141                	add	sp,sp,-16
    80000dee:	e406                	sd	ra,8(sp)
    80000df0:	e022                	sd	s0,0(sp)
    80000df2:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000df4:	00000097          	auipc	ra,0x0
    80000df8:	f9c080e7          	jalr	-100(ra) # 80000d90 <memmove>
}
    80000dfc:	60a2                	ld	ra,8(sp)
    80000dfe:	6402                	ld	s0,0(sp)
    80000e00:	0141                	add	sp,sp,16
    80000e02:	8082                	ret

0000000080000e04 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e04:	1141                	add	sp,sp,-16
    80000e06:	e422                	sd	s0,8(sp)
    80000e08:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e0a:	ce11                	beqz	a2,80000e26 <strncmp+0x22>
    80000e0c:	00054783          	lbu	a5,0(a0)
    80000e10:	cf89                	beqz	a5,80000e2a <strncmp+0x26>
    80000e12:	0005c703          	lbu	a4,0(a1)
    80000e16:	00f71a63          	bne	a4,a5,80000e2a <strncmp+0x26>
    n--, p++, q++;
    80000e1a:	367d                	addw	a2,a2,-1
    80000e1c:	0505                	add	a0,a0,1
    80000e1e:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e20:	f675                	bnez	a2,80000e0c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e22:	4501                	li	a0,0
    80000e24:	a801                	j	80000e34 <strncmp+0x30>
    80000e26:	4501                	li	a0,0
    80000e28:	a031                	j	80000e34 <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000e2a:	00054503          	lbu	a0,0(a0)
    80000e2e:	0005c783          	lbu	a5,0(a1)
    80000e32:	9d1d                	subw	a0,a0,a5
}
    80000e34:	6422                	ld	s0,8(sp)
    80000e36:	0141                	add	sp,sp,16
    80000e38:	8082                	ret

0000000080000e3a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e3a:	1141                	add	sp,sp,-16
    80000e3c:	e422                	sd	s0,8(sp)
    80000e3e:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e40:	87aa                	mv	a5,a0
    80000e42:	86b2                	mv	a3,a2
    80000e44:	367d                	addw	a2,a2,-1
    80000e46:	02d05563          	blez	a3,80000e70 <strncpy+0x36>
    80000e4a:	0785                	add	a5,a5,1
    80000e4c:	0005c703          	lbu	a4,0(a1)
    80000e50:	fee78fa3          	sb	a4,-1(a5)
    80000e54:	0585                	add	a1,a1,1
    80000e56:	f775                	bnez	a4,80000e42 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e58:	873e                	mv	a4,a5
    80000e5a:	9fb5                	addw	a5,a5,a3
    80000e5c:	37fd                	addw	a5,a5,-1
    80000e5e:	00c05963          	blez	a2,80000e70 <strncpy+0x36>
    *s++ = 0;
    80000e62:	0705                	add	a4,a4,1
    80000e64:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e68:	40e786bb          	subw	a3,a5,a4
    80000e6c:	fed04be3          	bgtz	a3,80000e62 <strncpy+0x28>
  return os;
}
    80000e70:	6422                	ld	s0,8(sp)
    80000e72:	0141                	add	sp,sp,16
    80000e74:	8082                	ret

0000000080000e76 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e76:	1141                	add	sp,sp,-16
    80000e78:	e422                	sd	s0,8(sp)
    80000e7a:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e7c:	02c05363          	blez	a2,80000ea2 <safestrcpy+0x2c>
    80000e80:	fff6069b          	addw	a3,a2,-1
    80000e84:	1682                	sll	a3,a3,0x20
    80000e86:	9281                	srl	a3,a3,0x20
    80000e88:	96ae                	add	a3,a3,a1
    80000e8a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e8c:	00d58963          	beq	a1,a3,80000e9e <safestrcpy+0x28>
    80000e90:	0585                	add	a1,a1,1
    80000e92:	0785                	add	a5,a5,1
    80000e94:	fff5c703          	lbu	a4,-1(a1)
    80000e98:	fee78fa3          	sb	a4,-1(a5)
    80000e9c:	fb65                	bnez	a4,80000e8c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e9e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	add	sp,sp,16
    80000ea6:	8082                	ret

0000000080000ea8 <strlen>:

int
strlen(const char *s)
{
    80000ea8:	1141                	add	sp,sp,-16
    80000eaa:	e422                	sd	s0,8(sp)
    80000eac:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eae:	00054783          	lbu	a5,0(a0)
    80000eb2:	cf91                	beqz	a5,80000ece <strlen+0x26>
    80000eb4:	0505                	add	a0,a0,1
    80000eb6:	87aa                	mv	a5,a0
    80000eb8:	86be                	mv	a3,a5
    80000eba:	0785                	add	a5,a5,1
    80000ebc:	fff7c703          	lbu	a4,-1(a5)
    80000ec0:	ff65                	bnez	a4,80000eb8 <strlen+0x10>
    80000ec2:	40a6853b          	subw	a0,a3,a0
    80000ec6:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	add	sp,sp,16
    80000ecc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ece:	4501                	li	a0,0
    80000ed0:	bfe5                	j	80000ec8 <strlen+0x20>

0000000080000ed2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ed2:	1141                	add	sp,sp,-16
    80000ed4:	e406                	sd	ra,8(sp)
    80000ed6:	e022                	sd	s0,0(sp)
    80000ed8:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	c84080e7          	jalr	-892(ra) # 80001b5e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ee2:	00009717          	auipc	a4,0x9
    80000ee6:	d0670713          	add	a4,a4,-762 # 80009be8 <started>
  if(cpuid() == 0){
    80000eea:	c539                	beqz	a0,80000f38 <main+0x66>
    while(started == 0)
    80000eec:	431c                	lw	a5,0(a4)
    80000eee:	2781                	sext.w	a5,a5
    80000ef0:	dff5                	beqz	a5,80000eec <main+0x1a>
      ;
    __sync_synchronize();
    80000ef2:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ef6:	00001097          	auipc	ra,0x1
    80000efa:	c68080e7          	jalr	-920(ra) # 80001b5e <cpuid>
    80000efe:	85aa                	mv	a1,a0
    80000f00:	00008517          	auipc	a0,0x8
    80000f04:	19850513          	add	a0,a0,408 # 80009098 <etext+0x98>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	6a2080e7          	jalr	1698(ra) # 800005aa <printf>
    kvminithart();    // turn on paging
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	0e0080e7          	jalr	224(ra) # 80000ff0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f18:	00002097          	auipc	ra,0x2
    80000f1c:	db8080e7          	jalr	-584(ra) # 80002cd0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f20:	00006097          	auipc	ra,0x6
    80000f24:	8e4080e7          	jalr	-1820(ra) # 80006804 <plicinithart>
  }

  init_mlfq();
    80000f28:	00006097          	auipc	ra,0x6
    80000f2c:	ef6080e7          	jalr	-266(ra) # 80006e1e <init_mlfq>

  scheduler();        
    80000f30:	00001097          	auipc	ra,0x1
    80000f34:	2aa080e7          	jalr	682(ra) # 800021da <scheduler>
    consoleinit();
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	538080e7          	jalr	1336(ra) # 80000470 <consoleinit>
    printfinit();
    80000f40:	00000097          	auipc	ra,0x0
    80000f44:	872080e7          	jalr	-1934(ra) # 800007b2 <printfinit>
    printf("\n");
    80000f48:	00008517          	auipc	a0,0x8
    80000f4c:	0c850513          	add	a0,a0,200 # 80009010 <etext+0x10>
    80000f50:	fffff097          	auipc	ra,0xfffff
    80000f54:	65a080e7          	jalr	1626(ra) # 800005aa <printf>
    printf("xv6 kernel is booting\n");
    80000f58:	00008517          	auipc	a0,0x8
    80000f5c:	12850513          	add	a0,a0,296 # 80009080 <etext+0x80>
    80000f60:	fffff097          	auipc	ra,0xfffff
    80000f64:	64a080e7          	jalr	1610(ra) # 800005aa <printf>
    printf("\n");
    80000f68:	00008517          	auipc	a0,0x8
    80000f6c:	0a850513          	add	a0,a0,168 # 80009010 <etext+0x10>
    80000f70:	fffff097          	auipc	ra,0xfffff
    80000f74:	63a080e7          	jalr	1594(ra) # 800005aa <printf>
    kinit();         // physical page allocator
    80000f78:	00000097          	auipc	ra,0x0
    80000f7c:	b94080e7          	jalr	-1132(ra) # 80000b0c <kinit>
    kvminit();       // create kernel page table
    80000f80:	00000097          	auipc	ra,0x0
    80000f84:	326080e7          	jalr	806(ra) # 800012a6 <kvminit>
    kvminithart();   // turn on paging
    80000f88:	00000097          	auipc	ra,0x0
    80000f8c:	068080e7          	jalr	104(ra) # 80000ff0 <kvminithart>
    procinit();      // process table
    80000f90:	00001097          	auipc	ra,0x1
    80000f94:	b08080e7          	jalr	-1272(ra) # 80001a98 <procinit>
    trapinit();      // trap vectors
    80000f98:	00002097          	auipc	ra,0x2
    80000f9c:	d10080e7          	jalr	-752(ra) # 80002ca8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fa0:	00002097          	auipc	ra,0x2
    80000fa4:	d30080e7          	jalr	-720(ra) # 80002cd0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fa8:	00006097          	auipc	ra,0x6
    80000fac:	842080e7          	jalr	-1982(ra) # 800067ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fb0:	00006097          	auipc	ra,0x6
    80000fb4:	854080e7          	jalr	-1964(ra) # 80006804 <plicinithart>
    binit();         // buffer cache
    80000fb8:	00003097          	auipc	ra,0x3
    80000fbc:	91e080e7          	jalr	-1762(ra) # 800038d6 <binit>
    iinit();         // inode table
    80000fc0:	00003097          	auipc	ra,0x3
    80000fc4:	fd4080e7          	jalr	-44(ra) # 80003f94 <iinit>
    fileinit();      // file table
    80000fc8:	00004097          	auipc	ra,0x4
    80000fcc:	f84080e7          	jalr	-124(ra) # 80004f4c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fd0:	00006097          	auipc	ra,0x6
    80000fd4:	93c080e7          	jalr	-1732(ra) # 8000690c <virtio_disk_init>
    userinit();      // first user process
    80000fd8:	00001097          	auipc	ra,0x1
    80000fdc:	ef4080e7          	jalr	-268(ra) # 80001ecc <userinit>
    __sync_synchronize();
    80000fe0:	0ff0000f          	fence
    started = 1;
    80000fe4:	4785                	li	a5,1
    80000fe6:	00009717          	auipc	a4,0x9
    80000fea:	c0f72123          	sw	a5,-1022(a4) # 80009be8 <started>
    80000fee:	bf2d                	j	80000f28 <main+0x56>

0000000080000ff0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000ff0:	1141                	add	sp,sp,-16
    80000ff2:	e422                	sd	s0,8(sp)
    80000ff4:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ffa:	00009797          	auipc	a5,0x9
    80000ffe:	bf67b783          	ld	a5,-1034(a5) # 80009bf0 <kernel_pagetable>
    80001002:	83b1                	srl	a5,a5,0xc
    80001004:	577d                	li	a4,-1
    80001006:	177e                	sll	a4,a4,0x3f
    80001008:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000100a:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000100e:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001012:	6422                	ld	s0,8(sp)
    80001014:	0141                	add	sp,sp,16
    80001016:	8082                	ret

0000000080001018 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001018:	7139                	add	sp,sp,-64
    8000101a:	fc06                	sd	ra,56(sp)
    8000101c:	f822                	sd	s0,48(sp)
    8000101e:	f426                	sd	s1,40(sp)
    80001020:	f04a                	sd	s2,32(sp)
    80001022:	ec4e                	sd	s3,24(sp)
    80001024:	e852                	sd	s4,16(sp)
    80001026:	e456                	sd	s5,8(sp)
    80001028:	e05a                	sd	s6,0(sp)
    8000102a:	0080                	add	s0,sp,64
    8000102c:	84aa                	mv	s1,a0
    8000102e:	89ae                	mv	s3,a1
    80001030:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001032:	57fd                	li	a5,-1
    80001034:	83e9                	srl	a5,a5,0x1a
    80001036:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001038:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000103a:	04b7f263          	bgeu	a5,a1,8000107e <walk+0x66>
    panic("walk");
    8000103e:	00008517          	auipc	a0,0x8
    80001042:	07250513          	add	a0,a0,114 # 800090b0 <etext+0xb0>
    80001046:	fffff097          	auipc	ra,0xfffff
    8000104a:	51a080e7          	jalr	1306(ra) # 80000560 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000104e:	060a8663          	beqz	s5,800010ba <walk+0xa2>
    80001052:	00000097          	auipc	ra,0x0
    80001056:	af6080e7          	jalr	-1290(ra) # 80000b48 <kalloc>
    8000105a:	84aa                	mv	s1,a0
    8000105c:	c529                	beqz	a0,800010a6 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000105e:	6605                	lui	a2,0x1
    80001060:	4581                	li	a1,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	cd2080e7          	jalr	-814(ra) # 80000d34 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000106a:	00c4d793          	srl	a5,s1,0xc
    8000106e:	07aa                	sll	a5,a5,0xa
    80001070:	0017e793          	or	a5,a5,1
    80001074:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001078:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd9f4f>
    8000107a:	036a0063          	beq	s4,s6,8000109a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000107e:	0149d933          	srl	s2,s3,s4
    80001082:	1ff97913          	and	s2,s2,511
    80001086:	090e                	sll	s2,s2,0x3
    80001088:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000108a:	00093483          	ld	s1,0(s2)
    8000108e:	0014f793          	and	a5,s1,1
    80001092:	dfd5                	beqz	a5,8000104e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001094:	80a9                	srl	s1,s1,0xa
    80001096:	04b2                	sll	s1,s1,0xc
    80001098:	b7c5                	j	80001078 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000109a:	00c9d513          	srl	a0,s3,0xc
    8000109e:	1ff57513          	and	a0,a0,511
    800010a2:	050e                	sll	a0,a0,0x3
    800010a4:	9526                	add	a0,a0,s1
}
    800010a6:	70e2                	ld	ra,56(sp)
    800010a8:	7442                	ld	s0,48(sp)
    800010aa:	74a2                	ld	s1,40(sp)
    800010ac:	7902                	ld	s2,32(sp)
    800010ae:	69e2                	ld	s3,24(sp)
    800010b0:	6a42                	ld	s4,16(sp)
    800010b2:	6aa2                	ld	s5,8(sp)
    800010b4:	6b02                	ld	s6,0(sp)
    800010b6:	6121                	add	sp,sp,64
    800010b8:	8082                	ret
        return 0;
    800010ba:	4501                	li	a0,0
    800010bc:	b7ed                	j	800010a6 <walk+0x8e>

00000000800010be <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010be:	57fd                	li	a5,-1
    800010c0:	83e9                	srl	a5,a5,0x1a
    800010c2:	00b7f463          	bgeu	a5,a1,800010ca <walkaddr+0xc>
    return 0;
    800010c6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010c8:	8082                	ret
{
    800010ca:	1141                	add	sp,sp,-16
    800010cc:	e406                	sd	ra,8(sp)
    800010ce:	e022                	sd	s0,0(sp)
    800010d0:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010d2:	4601                	li	a2,0
    800010d4:	00000097          	auipc	ra,0x0
    800010d8:	f44080e7          	jalr	-188(ra) # 80001018 <walk>
  if(pte == 0)
    800010dc:	c105                	beqz	a0,800010fc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010de:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010e0:	0117f693          	and	a3,a5,17
    800010e4:	4745                	li	a4,17
    return 0;
    800010e6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010e8:	00e68663          	beq	a3,a4,800010f4 <walkaddr+0x36>
}
    800010ec:	60a2                	ld	ra,8(sp)
    800010ee:	6402                	ld	s0,0(sp)
    800010f0:	0141                	add	sp,sp,16
    800010f2:	8082                	ret
  pa = PTE2PA(*pte);
    800010f4:	83a9                	srl	a5,a5,0xa
    800010f6:	00c79513          	sll	a0,a5,0xc
  return pa;
    800010fa:	bfcd                	j	800010ec <walkaddr+0x2e>
    return 0;
    800010fc:	4501                	li	a0,0
    800010fe:	b7fd                	j	800010ec <walkaddr+0x2e>

0000000080001100 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001100:	715d                	add	sp,sp,-80
    80001102:	e486                	sd	ra,72(sp)
    80001104:	e0a2                	sd	s0,64(sp)
    80001106:	fc26                	sd	s1,56(sp)
    80001108:	f84a                	sd	s2,48(sp)
    8000110a:	f44e                	sd	s3,40(sp)
    8000110c:	f052                	sd	s4,32(sp)
    8000110e:	ec56                	sd	s5,24(sp)
    80001110:	e85a                	sd	s6,16(sp)
    80001112:	e45e                	sd	s7,8(sp)
    80001114:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001116:	c639                	beqz	a2,80001164 <mappages+0x64>
    80001118:	8aaa                	mv	s5,a0
    8000111a:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000111c:	777d                	lui	a4,0xfffff
    8000111e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001122:	fff58993          	add	s3,a1,-1
    80001126:	99b2                	add	s3,s3,a2
    80001128:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000112c:	893e                	mv	s2,a5
    8000112e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001132:	6b85                	lui	s7,0x1
    80001134:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001138:	4605                	li	a2,1
    8000113a:	85ca                	mv	a1,s2
    8000113c:	8556                	mv	a0,s5
    8000113e:	00000097          	auipc	ra,0x0
    80001142:	eda080e7          	jalr	-294(ra) # 80001018 <walk>
    80001146:	cd1d                	beqz	a0,80001184 <mappages+0x84>
    if(*pte & PTE_V)
    80001148:	611c                	ld	a5,0(a0)
    8000114a:	8b85                	and	a5,a5,1
    8000114c:	e785                	bnez	a5,80001174 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000114e:	80b1                	srl	s1,s1,0xc
    80001150:	04aa                	sll	s1,s1,0xa
    80001152:	0164e4b3          	or	s1,s1,s6
    80001156:	0014e493          	or	s1,s1,1
    8000115a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000115c:	05390063          	beq	s2,s3,8000119c <mappages+0x9c>
    a += PGSIZE;
    80001160:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001162:	bfc9                	j	80001134 <mappages+0x34>
    panic("mappages: size");
    80001164:	00008517          	auipc	a0,0x8
    80001168:	f5450513          	add	a0,a0,-172 # 800090b8 <etext+0xb8>
    8000116c:	fffff097          	auipc	ra,0xfffff
    80001170:	3f4080e7          	jalr	1012(ra) # 80000560 <panic>
      panic("mappages: remap");
    80001174:	00008517          	auipc	a0,0x8
    80001178:	f5450513          	add	a0,a0,-172 # 800090c8 <etext+0xc8>
    8000117c:	fffff097          	auipc	ra,0xfffff
    80001180:	3e4080e7          	jalr	996(ra) # 80000560 <panic>
      return -1;
    80001184:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001186:	60a6                	ld	ra,72(sp)
    80001188:	6406                	ld	s0,64(sp)
    8000118a:	74e2                	ld	s1,56(sp)
    8000118c:	7942                	ld	s2,48(sp)
    8000118e:	79a2                	ld	s3,40(sp)
    80001190:	7a02                	ld	s4,32(sp)
    80001192:	6ae2                	ld	s5,24(sp)
    80001194:	6b42                	ld	s6,16(sp)
    80001196:	6ba2                	ld	s7,8(sp)
    80001198:	6161                	add	sp,sp,80
    8000119a:	8082                	ret
  return 0;
    8000119c:	4501                	li	a0,0
    8000119e:	b7e5                	j	80001186 <mappages+0x86>

00000000800011a0 <kvmmap>:
{
    800011a0:	1141                	add	sp,sp,-16
    800011a2:	e406                	sd	ra,8(sp)
    800011a4:	e022                	sd	s0,0(sp)
    800011a6:	0800                	add	s0,sp,16
    800011a8:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011aa:	86b2                	mv	a3,a2
    800011ac:	863e                	mv	a2,a5
    800011ae:	00000097          	auipc	ra,0x0
    800011b2:	f52080e7          	jalr	-174(ra) # 80001100 <mappages>
    800011b6:	e509                	bnez	a0,800011c0 <kvmmap+0x20>
}
    800011b8:	60a2                	ld	ra,8(sp)
    800011ba:	6402                	ld	s0,0(sp)
    800011bc:	0141                	add	sp,sp,16
    800011be:	8082                	ret
    panic("kvmmap");
    800011c0:	00008517          	auipc	a0,0x8
    800011c4:	f1850513          	add	a0,a0,-232 # 800090d8 <etext+0xd8>
    800011c8:	fffff097          	auipc	ra,0xfffff
    800011cc:	398080e7          	jalr	920(ra) # 80000560 <panic>

00000000800011d0 <kvmmake>:
{
    800011d0:	1101                	add	sp,sp,-32
    800011d2:	ec06                	sd	ra,24(sp)
    800011d4:	e822                	sd	s0,16(sp)
    800011d6:	e426                	sd	s1,8(sp)
    800011d8:	e04a                	sd	s2,0(sp)
    800011da:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	96c080e7          	jalr	-1684(ra) # 80000b48 <kalloc>
    800011e4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011e6:	6605                	lui	a2,0x1
    800011e8:	4581                	li	a1,0
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	b4a080e7          	jalr	-1206(ra) # 80000d34 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011f2:	4719                	li	a4,6
    800011f4:	6685                	lui	a3,0x1
    800011f6:	10000637          	lui	a2,0x10000
    800011fa:	100005b7          	lui	a1,0x10000
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	fa0080e7          	jalr	-96(ra) # 800011a0 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10001637          	lui	a2,0x10001
    80001210:	100015b7          	lui	a1,0x10001
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	f8a080e7          	jalr	-118(ra) # 800011a0 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	004006b7          	lui	a3,0x400
    80001224:	0c000637          	lui	a2,0xc000
    80001228:	0c0005b7          	lui	a1,0xc000
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	f72080e7          	jalr	-142(ra) # 800011a0 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001236:	00008917          	auipc	s2,0x8
    8000123a:	dca90913          	add	s2,s2,-566 # 80009000 <etext>
    8000123e:	4729                	li	a4,10
    80001240:	80008697          	auipc	a3,0x80008
    80001244:	dc068693          	add	a3,a3,-576 # 9000 <_entry-0x7fff7000>
    80001248:	4605                	li	a2,1
    8000124a:	067e                	sll	a2,a2,0x1f
    8000124c:	85b2                	mv	a1,a2
    8000124e:	8526                	mv	a0,s1
    80001250:	00000097          	auipc	ra,0x0
    80001254:	f50080e7          	jalr	-176(ra) # 800011a0 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001258:	46c5                	li	a3,17
    8000125a:	06ee                	sll	a3,a3,0x1b
    8000125c:	4719                	li	a4,6
    8000125e:	412686b3          	sub	a3,a3,s2
    80001262:	864a                	mv	a2,s2
    80001264:	85ca                	mv	a1,s2
    80001266:	8526                	mv	a0,s1
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f38080e7          	jalr	-200(ra) # 800011a0 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001270:	4729                	li	a4,10
    80001272:	6685                	lui	a3,0x1
    80001274:	00007617          	auipc	a2,0x7
    80001278:	d8c60613          	add	a2,a2,-628 # 80008000 <_trampoline>
    8000127c:	040005b7          	lui	a1,0x4000
    80001280:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001282:	05b2                	sll	a1,a1,0xc
    80001284:	8526                	mv	a0,s1
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	f1a080e7          	jalr	-230(ra) # 800011a0 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000128e:	8526                	mv	a0,s1
    80001290:	00000097          	auipc	ra,0x0
    80001294:	764080e7          	jalr	1892(ra) # 800019f4 <proc_mapstacks>
}
    80001298:	8526                	mv	a0,s1
    8000129a:	60e2                	ld	ra,24(sp)
    8000129c:	6442                	ld	s0,16(sp)
    8000129e:	64a2                	ld	s1,8(sp)
    800012a0:	6902                	ld	s2,0(sp)
    800012a2:	6105                	add	sp,sp,32
    800012a4:	8082                	ret

00000000800012a6 <kvminit>:
{
    800012a6:	1141                	add	sp,sp,-16
    800012a8:	e406                	sd	ra,8(sp)
    800012aa:	e022                	sd	s0,0(sp)
    800012ac:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    800012ae:	00000097          	auipc	ra,0x0
    800012b2:	f22080e7          	jalr	-222(ra) # 800011d0 <kvmmake>
    800012b6:	00009797          	auipc	a5,0x9
    800012ba:	92a7bd23          	sd	a0,-1734(a5) # 80009bf0 <kernel_pagetable>
}
    800012be:	60a2                	ld	ra,8(sp)
    800012c0:	6402                	ld	s0,0(sp)
    800012c2:	0141                	add	sp,sp,16
    800012c4:	8082                	ret

00000000800012c6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012c6:	715d                	add	sp,sp,-80
    800012c8:	e486                	sd	ra,72(sp)
    800012ca:	e0a2                	sd	s0,64(sp)
    800012cc:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ce:	03459793          	sll	a5,a1,0x34
    800012d2:	e39d                	bnez	a5,800012f8 <uvmunmap+0x32>
    800012d4:	f84a                	sd	s2,48(sp)
    800012d6:	f44e                	sd	s3,40(sp)
    800012d8:	f052                	sd	s4,32(sp)
    800012da:	ec56                	sd	s5,24(sp)
    800012dc:	e85a                	sd	s6,16(sp)
    800012de:	e45e                	sd	s7,8(sp)
    800012e0:	8a2a                	mv	s4,a0
    800012e2:	892e                	mv	s2,a1
    800012e4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e6:	0632                	sll	a2,a2,0xc
    800012e8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ec:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	6b05                	lui	s6,0x1
    800012f0:	0935fb63          	bgeu	a1,s3,80001386 <uvmunmap+0xc0>
    800012f4:	fc26                	sd	s1,56(sp)
    800012f6:	a8a9                	j	80001350 <uvmunmap+0x8a>
    800012f8:	fc26                	sd	s1,56(sp)
    800012fa:	f84a                	sd	s2,48(sp)
    800012fc:	f44e                	sd	s3,40(sp)
    800012fe:	f052                	sd	s4,32(sp)
    80001300:	ec56                	sd	s5,24(sp)
    80001302:	e85a                	sd	s6,16(sp)
    80001304:	e45e                	sd	s7,8(sp)
    panic("uvmunmap: not aligned");
    80001306:	00008517          	auipc	a0,0x8
    8000130a:	dda50513          	add	a0,a0,-550 # 800090e0 <etext+0xe0>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	252080e7          	jalr	594(ra) # 80000560 <panic>
      panic("uvmunmap: walk");
    80001316:	00008517          	auipc	a0,0x8
    8000131a:	de250513          	add	a0,a0,-542 # 800090f8 <etext+0xf8>
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	242080e7          	jalr	578(ra) # 80000560 <panic>
      panic("uvmunmap: not mapped");
    80001326:	00008517          	auipc	a0,0x8
    8000132a:	de250513          	add	a0,a0,-542 # 80009108 <etext+0x108>
    8000132e:	fffff097          	auipc	ra,0xfffff
    80001332:	232080e7          	jalr	562(ra) # 80000560 <panic>
      panic("uvmunmap: not a leaf");
    80001336:	00008517          	auipc	a0,0x8
    8000133a:	dea50513          	add	a0,a0,-534 # 80009120 <etext+0x120>
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	222080e7          	jalr	546(ra) # 80000560 <panic>
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001346:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134a:	995a                	add	s2,s2,s6
    8000134c:	03397c63          	bgeu	s2,s3,80001384 <uvmunmap+0xbe>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001350:	4601                	li	a2,0
    80001352:	85ca                	mv	a1,s2
    80001354:	8552                	mv	a0,s4
    80001356:	00000097          	auipc	ra,0x0
    8000135a:	cc2080e7          	jalr	-830(ra) # 80001018 <walk>
    8000135e:	84aa                	mv	s1,a0
    80001360:	d95d                	beqz	a0,80001316 <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)
    80001362:	6108                	ld	a0,0(a0)
    80001364:	00157793          	and	a5,a0,1
    80001368:	dfdd                	beqz	a5,80001326 <uvmunmap+0x60>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000136a:	3ff57793          	and	a5,a0,1023
    8000136e:	fd7784e3          	beq	a5,s7,80001336 <uvmunmap+0x70>
    if(do_free){
    80001372:	fc0a8ae3          	beqz	s5,80001346 <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
    80001376:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    80001378:	0532                	sll	a0,a0,0xc
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	6d0080e7          	jalr	1744(ra) # 80000a4a <kfree>
    80001382:	b7d1                	j	80001346 <uvmunmap+0x80>
    80001384:	74e2                	ld	s1,56(sp)
    80001386:	7942                	ld	s2,48(sp)
    80001388:	79a2                	ld	s3,40(sp)
    8000138a:	7a02                	ld	s4,32(sp)
    8000138c:	6ae2                	ld	s5,24(sp)
    8000138e:	6b42                	ld	s6,16(sp)
    80001390:	6ba2                	ld	s7,8(sp)
  }
}
    80001392:	60a6                	ld	ra,72(sp)
    80001394:	6406                	ld	s0,64(sp)
    80001396:	6161                	add	sp,sp,80
    80001398:	8082                	ret

000000008000139a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000139a:	1101                	add	sp,sp,-32
    8000139c:	ec06                	sd	ra,24(sp)
    8000139e:	e822                	sd	s0,16(sp)
    800013a0:	e426                	sd	s1,8(sp)
    800013a2:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	7a4080e7          	jalr	1956(ra) # 80000b48 <kalloc>
    800013ac:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ae:	c519                	beqz	a0,800013bc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b0:	6605                	lui	a2,0x1
    800013b2:	4581                	li	a1,0
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	980080e7          	jalr	-1664(ra) # 80000d34 <memset>
  return pagetable;
}
    800013bc:	8526                	mv	a0,s1
    800013be:	60e2                	ld	ra,24(sp)
    800013c0:	6442                	ld	s0,16(sp)
    800013c2:	64a2                	ld	s1,8(sp)
    800013c4:	6105                	add	sp,sp,32
    800013c6:	8082                	ret

00000000800013c8 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c8:	7179                	add	sp,sp,-48
    800013ca:	f406                	sd	ra,40(sp)
    800013cc:	f022                	sd	s0,32(sp)
    800013ce:	ec26                	sd	s1,24(sp)
    800013d0:	e84a                	sd	s2,16(sp)
    800013d2:	e44e                	sd	s3,8(sp)
    800013d4:	e052                	sd	s4,0(sp)
    800013d6:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d8:	6785                	lui	a5,0x1
    800013da:	04f67863          	bgeu	a2,a5,8000142a <uvmfirst+0x62>
    800013de:	8a2a                	mv	s4,a0
    800013e0:	89ae                	mv	s3,a1
    800013e2:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	764080e7          	jalr	1892(ra) # 80000b48 <kalloc>
    800013ec:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013ee:	6605                	lui	a2,0x1
    800013f0:	4581                	li	a1,0
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	942080e7          	jalr	-1726(ra) # 80000d34 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013fa:	4779                	li	a4,30
    800013fc:	86ca                	mv	a3,s2
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	8552                	mv	a0,s4
    80001404:	00000097          	auipc	ra,0x0
    80001408:	cfc080e7          	jalr	-772(ra) # 80001100 <mappages>
  memmove(mem, src, sz);
    8000140c:	8626                	mv	a2,s1
    8000140e:	85ce                	mv	a1,s3
    80001410:	854a                	mv	a0,s2
    80001412:	00000097          	auipc	ra,0x0
    80001416:	97e080e7          	jalr	-1666(ra) # 80000d90 <memmove>
}
    8000141a:	70a2                	ld	ra,40(sp)
    8000141c:	7402                	ld	s0,32(sp)
    8000141e:	64e2                	ld	s1,24(sp)
    80001420:	6942                	ld	s2,16(sp)
    80001422:	69a2                	ld	s3,8(sp)
    80001424:	6a02                	ld	s4,0(sp)
    80001426:	6145                	add	sp,sp,48
    80001428:	8082                	ret
    panic("uvmfirst: more than a page");
    8000142a:	00008517          	auipc	a0,0x8
    8000142e:	d0e50513          	add	a0,a0,-754 # 80009138 <etext+0x138>
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	12e080e7          	jalr	302(ra) # 80000560 <panic>

000000008000143a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000143a:	1101                	add	sp,sp,-32
    8000143c:	ec06                	sd	ra,24(sp)
    8000143e:	e822                	sd	s0,16(sp)
    80001440:	e426                	sd	s1,8(sp)
    80001442:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001444:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001446:	00b67d63          	bgeu	a2,a1,80001460 <uvmdealloc+0x26>
    8000144a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000144c:	6785                	lui	a5,0x1
    8000144e:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001450:	00f60733          	add	a4,a2,a5
    80001454:	76fd                	lui	a3,0xfffff
    80001456:	8f75                	and	a4,a4,a3
    80001458:	97ae                	add	a5,a5,a1
    8000145a:	8ff5                	and	a5,a5,a3
    8000145c:	00f76863          	bltu	a4,a5,8000146c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001460:	8526                	mv	a0,s1
    80001462:	60e2                	ld	ra,24(sp)
    80001464:	6442                	ld	s0,16(sp)
    80001466:	64a2                	ld	s1,8(sp)
    80001468:	6105                	add	sp,sp,32
    8000146a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000146c:	8f99                	sub	a5,a5,a4
    8000146e:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001470:	4685                	li	a3,1
    80001472:	0007861b          	sext.w	a2,a5
    80001476:	85ba                	mv	a1,a4
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	e4e080e7          	jalr	-434(ra) # 800012c6 <uvmunmap>
    80001480:	b7c5                	j	80001460 <uvmdealloc+0x26>

0000000080001482 <uvmalloc>:
  if(newsz < oldsz)
    80001482:	0ab66b63          	bltu	a2,a1,80001538 <uvmalloc+0xb6>
{
    80001486:	7139                	add	sp,sp,-64
    80001488:	fc06                	sd	ra,56(sp)
    8000148a:	f822                	sd	s0,48(sp)
    8000148c:	ec4e                	sd	s3,24(sp)
    8000148e:	e852                	sd	s4,16(sp)
    80001490:	e456                	sd	s5,8(sp)
    80001492:	0080                	add	s0,sp,64
    80001494:	8aaa                	mv	s5,a0
    80001496:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001498:	6785                	lui	a5,0x1
    8000149a:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000149c:	95be                	add	a1,a1,a5
    8000149e:	77fd                	lui	a5,0xfffff
    800014a0:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a4:	08c9fc63          	bgeu	s3,a2,8000153c <uvmalloc+0xba>
    800014a8:	f426                	sd	s1,40(sp)
    800014aa:	f04a                	sd	s2,32(sp)
    800014ac:	e05a                	sd	s6,0(sp)
    800014ae:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b0:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    800014b4:	fffff097          	auipc	ra,0xfffff
    800014b8:	694080e7          	jalr	1684(ra) # 80000b48 <kalloc>
    800014bc:	84aa                	mv	s1,a0
    if(mem == 0){
    800014be:	c915                	beqz	a0,800014f2 <uvmalloc+0x70>
    memset(mem, 0, PGSIZE);
    800014c0:	6605                	lui	a2,0x1
    800014c2:	4581                	li	a1,0
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	870080e7          	jalr	-1936(ra) # 80000d34 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014cc:	875a                	mv	a4,s6
    800014ce:	86a6                	mv	a3,s1
    800014d0:	6605                	lui	a2,0x1
    800014d2:	85ca                	mv	a1,s2
    800014d4:	8556                	mv	a0,s5
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	c2a080e7          	jalr	-982(ra) # 80001100 <mappages>
    800014de:	ed05                	bnez	a0,80001516 <uvmalloc+0x94>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e0:	6785                	lui	a5,0x1
    800014e2:	993e                	add	s2,s2,a5
    800014e4:	fd4968e3          	bltu	s2,s4,800014b4 <uvmalloc+0x32>
  return newsz;
    800014e8:	8552                	mv	a0,s4
    800014ea:	74a2                	ld	s1,40(sp)
    800014ec:	7902                	ld	s2,32(sp)
    800014ee:	6b02                	ld	s6,0(sp)
    800014f0:	a821                	j	80001508 <uvmalloc+0x86>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f42080e7          	jalr	-190(ra) # 8000143a <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
    80001502:	74a2                	ld	s1,40(sp)
    80001504:	7902                	ld	s2,32(sp)
    80001506:	6b02                	ld	s6,0(sp)
}
    80001508:	70e2                	ld	ra,56(sp)
    8000150a:	7442                	ld	s0,48(sp)
    8000150c:	69e2                	ld	s3,24(sp)
    8000150e:	6a42                	ld	s4,16(sp)
    80001510:	6aa2                	ld	s5,8(sp)
    80001512:	6121                	add	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	532080e7          	jalr	1330(ra) # 80000a4a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f14080e7          	jalr	-236(ra) # 8000143a <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	74a2                	ld	s1,40(sp)
    80001532:	7902                	ld	s2,32(sp)
    80001534:	6b02                	ld	s6,0(sp)
    80001536:	bfc9                	j	80001508 <uvmalloc+0x86>
    return oldsz;
    80001538:	852e                	mv	a0,a1
}
    8000153a:	8082                	ret
  return newsz;
    8000153c:	8532                	mv	a0,a2
    8000153e:	b7e9                	j	80001508 <uvmalloc+0x86>

0000000080001540 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001540:	7179                	add	sp,sp,-48
    80001542:	f406                	sd	ra,40(sp)
    80001544:	f022                	sd	s0,32(sp)
    80001546:	ec26                	sd	s1,24(sp)
    80001548:	e84a                	sd	s2,16(sp)
    8000154a:	e44e                	sd	s3,8(sp)
    8000154c:	e052                	sd	s4,0(sp)
    8000154e:	1800                	add	s0,sp,48
    80001550:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001552:	84aa                	mv	s1,a0
    80001554:	6905                	lui	s2,0x1
    80001556:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001558:	4985                	li	s3,1
    8000155a:	a829                	j	80001574 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000155c:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000155e:	00c79513          	sll	a0,a5,0xc
    80001562:	00000097          	auipc	ra,0x0
    80001566:	fde080e7          	jalr	-34(ra) # 80001540 <freewalk>
      pagetable[i] = 0;
    8000156a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000156e:	04a1                	add	s1,s1,8
    80001570:	03248163          	beq	s1,s2,80001592 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001574:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001576:	00f7f713          	and	a4,a5,15
    8000157a:	ff3701e3          	beq	a4,s3,8000155c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000157e:	8b85                	and	a5,a5,1
    80001580:	d7fd                	beqz	a5,8000156e <freewalk+0x2e>
      panic("freewalk: leaf");
    80001582:	00008517          	auipc	a0,0x8
    80001586:	bd650513          	add	a0,a0,-1066 # 80009158 <etext+0x158>
    8000158a:	fffff097          	auipc	ra,0xfffff
    8000158e:	fd6080e7          	jalr	-42(ra) # 80000560 <panic>
    }
  }
  kfree((void*)pagetable);
    80001592:	8552                	mv	a0,s4
    80001594:	fffff097          	auipc	ra,0xfffff
    80001598:	4b6080e7          	jalr	1206(ra) # 80000a4a <kfree>
}
    8000159c:	70a2                	ld	ra,40(sp)
    8000159e:	7402                	ld	s0,32(sp)
    800015a0:	64e2                	ld	s1,24(sp)
    800015a2:	6942                	ld	s2,16(sp)
    800015a4:	69a2                	ld	s3,8(sp)
    800015a6:	6a02                	ld	s4,0(sp)
    800015a8:	6145                	add	sp,sp,48
    800015aa:	8082                	ret

00000000800015ac <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015ac:	1101                	add	sp,sp,-32
    800015ae:	ec06                	sd	ra,24(sp)
    800015b0:	e822                	sd	s0,16(sp)
    800015b2:	e426                	sd	s1,8(sp)
    800015b4:	1000                	add	s0,sp,32
    800015b6:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b8:	e999                	bnez	a1,800015ce <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ba:	8526                	mv	a0,s1
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	f84080e7          	jalr	-124(ra) # 80001540 <freewalk>
}
    800015c4:	60e2                	ld	ra,24(sp)
    800015c6:	6442                	ld	s0,16(sp)
    800015c8:	64a2                	ld	s1,8(sp)
    800015ca:	6105                	add	sp,sp,32
    800015cc:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015ce:	6785                	lui	a5,0x1
    800015d0:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015d2:	95be                	add	a1,a1,a5
    800015d4:	4685                	li	a3,1
    800015d6:	00c5d613          	srl	a2,a1,0xc
    800015da:	4581                	li	a1,0
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	cea080e7          	jalr	-790(ra) # 800012c6 <uvmunmap>
    800015e4:	bfd9                	j	800015ba <uvmfree+0xe>

00000000800015e6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem; // no longer required since not allocation memory

  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	c269                	beqz	a2,800016a8 <uvmcopy+0xc2>
{
    800015e8:	7139                	add	sp,sp,-64
    800015ea:	fc06                	sd	ra,56(sp)
    800015ec:	f822                	sd	s0,48(sp)
    800015ee:	f426                	sd	s1,40(sp)
    800015f0:	f04a                	sd	s2,32(sp)
    800015f2:	ec4e                	sd	s3,24(sp)
    800015f4:	e852                	sd	s4,16(sp)
    800015f6:	e456                	sd	s5,8(sp)
    800015f8:	0080                	add	s0,sp,64
    800015fa:	8a2a                	mv	s4,a0
    800015fc:	89ae                	mv	s3,a1
    800015fe:	8932                	mv	s2,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001600:	4481                	li	s1,0
    // adding flag for COW
    flags = flags | PTE_COW;

    // updating PTE
    // mapping physial address - 
    *pte = PA2PTE(pa);
    80001602:	7afd                	lui	s5,0xfffff
    80001604:	002ada93          	srl	s5,s5,0x2
    80001608:	a0a1                	j	80001650 <uvmcopy+0x6a>
      panic("uvmcopy: pte should exist");
    8000160a:	00008517          	auipc	a0,0x8
    8000160e:	b5e50513          	add	a0,a0,-1186 # 80009168 <etext+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f4e080e7          	jalr	-178(ra) # 80000560 <panic>
      panic("uvmcopy: page not present");
    8000161a:	00008517          	auipc	a0,0x8
    8000161e:	b6e50513          	add	a0,a0,-1170 # 80009188 <etext+0x188>
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	f3e080e7          	jalr	-194(ra) # 80000560 <panic>
    *pte = PA2PTE(pa);
    8000162a:	0157f7b3          	and	a5,a5,s5
    // adding new flags
    *pte = *pte | flags;
    8000162e:	20076613          	or	a2,a4,512
    80001632:	8fd1                	or	a5,a5,a2
    80001634:	e11c                	sd	a5,0(a0)

    // map parents pa's to child
    if (mappages(new, i, PGSIZE, pa, flags) != 0){
    80001636:	8732                	mv	a4,a2
    80001638:	6605                	lui	a2,0x1
    8000163a:	85a6                	mv	a1,s1
    8000163c:	854e                	mv	a0,s3
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	ac2080e7          	jalr	-1342(ra) # 80001100 <mappages>
    80001646:	ed15                	bnez	a0,80001682 <uvmcopy+0x9c>
  for(i = 0; i < sz; i += PGSIZE){
    80001648:	6785                	lui	a5,0x1
    8000164a:	94be                	add	s1,s1,a5
    8000164c:	0524f563          	bgeu	s1,s2,80001696 <uvmcopy+0xb0>
    if((pte = walk(old, i, 0)) == 0)
    80001650:	4601                	li	a2,0
    80001652:	85a6                	mv	a1,s1
    80001654:	8552                	mv	a0,s4
    80001656:	00000097          	auipc	ra,0x0
    8000165a:	9c2080e7          	jalr	-1598(ra) # 80001018 <walk>
    8000165e:	d555                	beqz	a0,8000160a <uvmcopy+0x24>
    if((*pte & PTE_V) == 0)
    80001660:	611c                	ld	a5,0(a0)
    80001662:	0017f713          	and	a4,a5,1
    80001666:	db55                	beqz	a4,8000161a <uvmcopy+0x34>
    pa = PTE2PA(*pte);
    80001668:	00a7d693          	srl	a3,a5,0xa
    8000166c:	06b2                	sll	a3,a3,0xc
    flags = PTE_FLAGS(*pte); // gets lower 10 bits of PTE
    8000166e:	0007859b          	sext.w	a1,a5
    if ((flags & PTE_W) != 0){
    80001672:	0047f613          	and	a2,a5,4
      flags = flags & (~PTE_W); // removing write
    80001676:	3fb5f713          	and	a4,a1,1019
    if ((flags & PTE_W) != 0){
    8000167a:	fa45                	bnez	a2,8000162a <uvmcopy+0x44>
    flags = PTE_FLAGS(*pte); // gets lower 10 bits of PTE
    8000167c:	3ff5f713          	and	a4,a1,1023
    80001680:	b76d                	j	8000162a <uvmcopy+0x44>
    
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001682:	4685                	li	a3,1
    80001684:	00c4d613          	srl	a2,s1,0xc
    80001688:	4581                	li	a1,0
    8000168a:	854e                	mv	a0,s3
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	c3a080e7          	jalr	-966(ra) # 800012c6 <uvmunmap>
  return -1;
    80001694:	557d                	li	a0,-1
}
    80001696:	70e2                	ld	ra,56(sp)
    80001698:	7442                	ld	s0,48(sp)
    8000169a:	74a2                	ld	s1,40(sp)
    8000169c:	7902                	ld	s2,32(sp)
    8000169e:	69e2                	ld	s3,24(sp)
    800016a0:	6a42                	ld	s4,16(sp)
    800016a2:	6aa2                	ld	s5,8(sp)
    800016a4:	6121                	add	sp,sp,64
    800016a6:	8082                	ret
  return 0;
    800016a8:	4501                	li	a0,0
}
    800016aa:	8082                	ret

00000000800016ac <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ac:	1141                	add	sp,sp,-16
    800016ae:	e406                	sd	ra,8(sp)
    800016b0:	e022                	sd	s0,0(sp)
    800016b2:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016b4:	4601                	li	a2,0
    800016b6:	00000097          	auipc	ra,0x0
    800016ba:	962080e7          	jalr	-1694(ra) # 80001018 <walk>
  if(pte == 0)
    800016be:	c901                	beqz	a0,800016ce <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c0:	611c                	ld	a5,0(a0)
    800016c2:	9bbd                	and	a5,a5,-17
    800016c4:	e11c                	sd	a5,0(a0)
}
    800016c6:	60a2                	ld	ra,8(sp)
    800016c8:	6402                	ld	s0,0(sp)
    800016ca:	0141                	add	sp,sp,16
    800016cc:	8082                	ret
    panic("uvmclear");
    800016ce:	00008517          	auipc	a0,0x8
    800016d2:	ada50513          	add	a0,a0,-1318 # 800091a8 <etext+0x1a8>
    800016d6:	fffff097          	auipc	ra,0xfffff
    800016da:	e8a080e7          	jalr	-374(ra) # 80000560 <panic>

00000000800016de <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016de:	cafd                	beqz	a3,800017d4 <copyout+0xf6>
{
    800016e0:	711d                	add	sp,sp,-96
    800016e2:	ec86                	sd	ra,88(sp)
    800016e4:	e8a2                	sd	s0,80(sp)
    800016e6:	e0ca                	sd	s2,64(sp)
    800016e8:	f852                	sd	s4,48(sp)
    800016ea:	f05a                	sd	s6,32(sp)
    800016ec:	ec5e                	sd	s7,24(sp)
    800016ee:	e862                	sd	s8,16(sp)
    800016f0:	1080                	add	s0,sp,96
    800016f2:	8c2a                	mv	s8,a0
    800016f4:	8b2e                	mv	s6,a1
    800016f6:	8bb2                	mv	s7,a2
    800016f8:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800016fa:	797d                	lui	s2,0xfffff
    800016fc:	0125f933          	and	s2,a1,s2
    if (va0 >= MAXVA)
    80001700:	57fd                	li	a5,-1
    80001702:	83e9                	srl	a5,a5,0x1a
    80001704:	0d27ea63          	bltu	a5,s2,800017d8 <copyout+0xfa>
    80001708:	e4a6                	sd	s1,72(sp)
    8000170a:	fc4e                	sd	s3,56(sp)
    8000170c:	f456                	sd	s5,40(sp)
    8000170e:	e466                	sd	s9,8(sp)
    80001710:	e06a                	sd	s10,0(sp)
    80001712:	8cbe                	mv	s9,a5
    80001714:	a025                	j	8000173c <copyout+0x5e>
    }

    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001716:	412b0533          	sub	a0,s6,s2
    8000171a:	000a861b          	sext.w	a2,s5
    8000171e:	85de                	mv	a1,s7
    80001720:	9526                	add	a0,a0,s1
    80001722:	fffff097          	auipc	ra,0xfffff
    80001726:	66e080e7          	jalr	1646(ra) # 80000d90 <memmove>

    len -= n;
    8000172a:	415a0a33          	sub	s4,s4,s5
    src += n;
    8000172e:	9bd6                	add	s7,s7,s5
  while(len > 0){
    80001730:	080a0b63          	beqz	s4,800017c6 <copyout+0xe8>
    if (va0 >= MAXVA)
    80001734:	0b3ce463          	bltu	s9,s3,800017dc <copyout+0xfe>
    80001738:	894e                	mv	s2,s3
    8000173a:	8b4e                	mv	s6,s3
    pa0 = walkaddr(pagetable, va0);
    8000173c:	85ca                	mv	a1,s2
    8000173e:	8562                	mv	a0,s8
    80001740:	00000097          	auipc	ra,0x0
    80001744:	97e080e7          	jalr	-1666(ra) # 800010be <walkaddr>
    80001748:	84aa                	mv	s1,a0
    if(pa0 == 0)
    8000174a:	c145                	beqz	a0,800017ea <copyout+0x10c>
    pte_t* pte = walk(pagetable, va0, 0);
    8000174c:	4601                	li	a2,0
    8000174e:	85ca                	mv	a1,s2
    80001750:	8562                	mv	a0,s8
    80001752:	00000097          	auipc	ra,0x0
    80001756:	8c6080e7          	jalr	-1850(ra) # 80001018 <walk>
    8000175a:	89aa                	mv	s3,a0
    if (pte == 0)
    8000175c:	c555                	beqz	a0,80001808 <copyout+0x12a>
    uint64 flags = PTE_FLAGS(*pte);
    8000175e:	00053d03          	ld	s10,0(a0)
    if ((flags & PTE_COW) != 0){ // whether it is cow
    80001762:	200d7793          	and	a5,s10,512
    80001766:	cba1                	beqz	a5,800017b6 <copyout+0xd8>
      uint64 pa = PTE2PA(*pte);
    80001768:	00ad5a93          	srl	s5,s10,0xa
    8000176c:	0ab2                	sll	s5,s5,0xc
      if (pa == 0)
    8000176e:	0a0a8463          	beqz	s5,80001816 <copyout+0x138>
       flags = flags & (~PTE_COW);
    80001772:	1ffd7d13          	and	s10,s10,511
       char* mem = kalloc();
    80001776:	fffff097          	auipc	ra,0xfffff
    8000177a:	3d2080e7          	jalr	978(ra) # 80000b48 <kalloc>
    8000177e:	84aa                	mv	s1,a0
      if (mem == 0)
    80001780:	c155                	beqz	a0,80001824 <copyout+0x146>
      memmove(mem, (void*)pa, PGSIZE);
    80001782:	6605                	lui	a2,0x1
    80001784:	85d6                	mv	a1,s5
    80001786:	fffff097          	auipc	ra,0xfffff
    8000178a:	60a080e7          	jalr	1546(ra) # 80000d90 <memmove>
      *pte = PA2PTE(mem);
    8000178e:	80b1                	srl	s1,s1,0xc
    80001790:	04aa                	sll	s1,s1,0xa
      *pte = *pte | flags;
    80001792:	01a4e4b3          	or	s1,s1,s10
    80001796:	0044e493          	or	s1,s1,4
    8000179a:	0099b023          	sd	s1,0(s3) # 1000 <_entry-0x7ffff000>
      kfree((void*) pa);
    8000179e:	8556                	mv	a0,s5
    800017a0:	fffff097          	auipc	ra,0xfffff
    800017a4:	2aa080e7          	jalr	682(ra) # 80000a4a <kfree>
      pa0 = walkaddr(pagetable, va0);
    800017a8:	85ca                	mv	a1,s2
    800017aa:	8562                	mv	a0,s8
    800017ac:	00000097          	auipc	ra,0x0
    800017b0:	912080e7          	jalr	-1774(ra) # 800010be <walkaddr>
    800017b4:	84aa                	mv	s1,a0
    n = PGSIZE - (dstva - va0);
    800017b6:	6985                	lui	s3,0x1
    800017b8:	99ca                	add	s3,s3,s2
    800017ba:	41698ab3          	sub	s5,s3,s6
    if(n > len)
    800017be:	f55a7ce3          	bgeu	s4,s5,80001716 <copyout+0x38>
    800017c2:	8ad2                	mv	s5,s4
    800017c4:	bf89                	j	80001716 <copyout+0x38>
    dstva = va0 + PGSIZE;
  }
  return 0;
    800017c6:	4501                	li	a0,0
    800017c8:	64a6                	ld	s1,72(sp)
    800017ca:	79e2                	ld	s3,56(sp)
    800017cc:	7aa2                	ld	s5,40(sp)
    800017ce:	6ca2                	ld	s9,8(sp)
    800017d0:	6d02                	ld	s10,0(sp)
    800017d2:	a015                	j	800017f6 <copyout+0x118>
    800017d4:	4501                	li	a0,0
}
    800017d6:	8082                	ret
      return -1;
    800017d8:	557d                	li	a0,-1
    800017da:	a831                	j	800017f6 <copyout+0x118>
    800017dc:	557d                	li	a0,-1
    800017de:	64a6                	ld	s1,72(sp)
    800017e0:	79e2                	ld	s3,56(sp)
    800017e2:	7aa2                	ld	s5,40(sp)
    800017e4:	6ca2                	ld	s9,8(sp)
    800017e6:	6d02                	ld	s10,0(sp)
    800017e8:	a039                	j	800017f6 <copyout+0x118>
      return -1;
    800017ea:	557d                	li	a0,-1
    800017ec:	64a6                	ld	s1,72(sp)
    800017ee:	79e2                	ld	s3,56(sp)
    800017f0:	7aa2                	ld	s5,40(sp)
    800017f2:	6ca2                	ld	s9,8(sp)
    800017f4:	6d02                	ld	s10,0(sp)
}
    800017f6:	60e6                	ld	ra,88(sp)
    800017f8:	6446                	ld	s0,80(sp)
    800017fa:	6906                	ld	s2,64(sp)
    800017fc:	7a42                	ld	s4,48(sp)
    800017fe:	7b02                	ld	s6,32(sp)
    80001800:	6be2                	ld	s7,24(sp)
    80001802:	6c42                	ld	s8,16(sp)
    80001804:	6125                	add	sp,sp,96
    80001806:	8082                	ret
      return -1;
    80001808:	557d                	li	a0,-1
    8000180a:	64a6                	ld	s1,72(sp)
    8000180c:	79e2                	ld	s3,56(sp)
    8000180e:	7aa2                	ld	s5,40(sp)
    80001810:	6ca2                	ld	s9,8(sp)
    80001812:	6d02                	ld	s10,0(sp)
    80001814:	b7cd                	j	800017f6 <copyout+0x118>
        return -1;
    80001816:	557d                	li	a0,-1
    80001818:	64a6                	ld	s1,72(sp)
    8000181a:	79e2                	ld	s3,56(sp)
    8000181c:	7aa2                	ld	s5,40(sp)
    8000181e:	6ca2                	ld	s9,8(sp)
    80001820:	6d02                	ld	s10,0(sp)
    80001822:	bfd1                	j	800017f6 <copyout+0x118>
         return -1;
    80001824:	557d                	li	a0,-1
    80001826:	64a6                	ld	s1,72(sp)
    80001828:	79e2                	ld	s3,56(sp)
    8000182a:	7aa2                	ld	s5,40(sp)
    8000182c:	6ca2                	ld	s9,8(sp)
    8000182e:	6d02                	ld	s10,0(sp)
    80001830:	b7d9                	j	800017f6 <copyout+0x118>

0000000080001832 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001832:	caa5                	beqz	a3,800018a2 <copyin+0x70>
{
    80001834:	715d                	add	sp,sp,-80
    80001836:	e486                	sd	ra,72(sp)
    80001838:	e0a2                	sd	s0,64(sp)
    8000183a:	fc26                	sd	s1,56(sp)
    8000183c:	f84a                	sd	s2,48(sp)
    8000183e:	f44e                	sd	s3,40(sp)
    80001840:	f052                	sd	s4,32(sp)
    80001842:	ec56                	sd	s5,24(sp)
    80001844:	e85a                	sd	s6,16(sp)
    80001846:	e45e                	sd	s7,8(sp)
    80001848:	e062                	sd	s8,0(sp)
    8000184a:	0880                	add	s0,sp,80
    8000184c:	8b2a                	mv	s6,a0
    8000184e:	8a2e                	mv	s4,a1
    80001850:	8c32                	mv	s8,a2
    80001852:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001854:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001856:	6a85                	lui	s5,0x1
    80001858:	a01d                	j	8000187e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000185a:	018505b3          	add	a1,a0,s8
    8000185e:	0004861b          	sext.w	a2,s1
    80001862:	412585b3          	sub	a1,a1,s2
    80001866:	8552                	mv	a0,s4
    80001868:	fffff097          	auipc	ra,0xfffff
    8000186c:	528080e7          	jalr	1320(ra) # 80000d90 <memmove>

    len -= n;
    80001870:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001874:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001876:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000187a:	02098263          	beqz	s3,8000189e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000187e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001882:	85ca                	mv	a1,s2
    80001884:	855a                	mv	a0,s6
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	838080e7          	jalr	-1992(ra) # 800010be <walkaddr>
    if(pa0 == 0)
    8000188e:	cd01                	beqz	a0,800018a6 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001890:	418904b3          	sub	s1,s2,s8
    80001894:	94d6                	add	s1,s1,s5
    if(n > len)
    80001896:	fc99f2e3          	bgeu	s3,s1,8000185a <copyin+0x28>
    8000189a:	84ce                	mv	s1,s3
    8000189c:	bf7d                	j	8000185a <copyin+0x28>
  }
  return 0;
    8000189e:	4501                	li	a0,0
    800018a0:	a021                	j	800018a8 <copyin+0x76>
    800018a2:	4501                	li	a0,0
}
    800018a4:	8082                	ret
      return -1;
    800018a6:	557d                	li	a0,-1
}
    800018a8:	60a6                	ld	ra,72(sp)
    800018aa:	6406                	ld	s0,64(sp)
    800018ac:	74e2                	ld	s1,56(sp)
    800018ae:	7942                	ld	s2,48(sp)
    800018b0:	79a2                	ld	s3,40(sp)
    800018b2:	7a02                	ld	s4,32(sp)
    800018b4:	6ae2                	ld	s5,24(sp)
    800018b6:	6b42                	ld	s6,16(sp)
    800018b8:	6ba2                	ld	s7,8(sp)
    800018ba:	6c02                	ld	s8,0(sp)
    800018bc:	6161                	add	sp,sp,80
    800018be:	8082                	ret

00000000800018c0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018c0:	cacd                	beqz	a3,80001972 <copyinstr+0xb2>
{
    800018c2:	715d                	add	sp,sp,-80
    800018c4:	e486                	sd	ra,72(sp)
    800018c6:	e0a2                	sd	s0,64(sp)
    800018c8:	fc26                	sd	s1,56(sp)
    800018ca:	f84a                	sd	s2,48(sp)
    800018cc:	f44e                	sd	s3,40(sp)
    800018ce:	f052                	sd	s4,32(sp)
    800018d0:	ec56                	sd	s5,24(sp)
    800018d2:	e85a                	sd	s6,16(sp)
    800018d4:	e45e                	sd	s7,8(sp)
    800018d6:	0880                	add	s0,sp,80
    800018d8:	8a2a                	mv	s4,a0
    800018da:	8b2e                	mv	s6,a1
    800018dc:	8bb2                	mv	s7,a2
    800018de:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800018e0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018e2:	6985                	lui	s3,0x1
    800018e4:	a825                	j	8000191c <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018e6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018ea:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018ec:	37fd                	addw	a5,a5,-1
    800018ee:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018f2:	60a6                	ld	ra,72(sp)
    800018f4:	6406                	ld	s0,64(sp)
    800018f6:	74e2                	ld	s1,56(sp)
    800018f8:	7942                	ld	s2,48(sp)
    800018fa:	79a2                	ld	s3,40(sp)
    800018fc:	7a02                	ld	s4,32(sp)
    800018fe:	6ae2                	ld	s5,24(sp)
    80001900:	6b42                	ld	s6,16(sp)
    80001902:	6ba2                	ld	s7,8(sp)
    80001904:	6161                	add	sp,sp,80
    80001906:	8082                	ret
    80001908:	fff90713          	add	a4,s2,-1 # ffffffffffffefff <end+0xffffffff7ffd9f57>
    8000190c:	9742                	add	a4,a4,a6
      --max;
    8000190e:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    80001912:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001916:	04e58663          	beq	a1,a4,80001962 <copyinstr+0xa2>
{
    8000191a:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    8000191c:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001920:	85a6                	mv	a1,s1
    80001922:	8552                	mv	a0,s4
    80001924:	fffff097          	auipc	ra,0xfffff
    80001928:	79a080e7          	jalr	1946(ra) # 800010be <walkaddr>
    if(pa0 == 0)
    8000192c:	cd0d                	beqz	a0,80001966 <copyinstr+0xa6>
    n = PGSIZE - (srcva - va0);
    8000192e:	417486b3          	sub	a3,s1,s7
    80001932:	96ce                	add	a3,a3,s3
    if(n > max)
    80001934:	00d97363          	bgeu	s2,a3,8000193a <copyinstr+0x7a>
    80001938:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    8000193a:	955e                	add	a0,a0,s7
    8000193c:	8d05                	sub	a0,a0,s1
    while(n > 0){
    8000193e:	c695                	beqz	a3,8000196a <copyinstr+0xaa>
    80001940:	87da                	mv	a5,s6
    80001942:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001944:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001948:	96da                	add	a3,a3,s6
    8000194a:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000194c:	00f60733          	add	a4,a2,a5
    80001950:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9f58>
    80001954:	db49                	beqz	a4,800018e6 <copyinstr+0x26>
        *dst = *p;
    80001956:	00e78023          	sb	a4,0(a5)
      dst++;
    8000195a:	0785                	add	a5,a5,1
    while(n > 0){
    8000195c:	fed797e3          	bne	a5,a3,8000194a <copyinstr+0x8a>
    80001960:	b765                	j	80001908 <copyinstr+0x48>
    80001962:	4781                	li	a5,0
    80001964:	b761                	j	800018ec <copyinstr+0x2c>
      return -1;
    80001966:	557d                	li	a0,-1
    80001968:	b769                	j	800018f2 <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    8000196a:	6b85                	lui	s7,0x1
    8000196c:	9ba6                	add	s7,s7,s1
    8000196e:	87da                	mv	a5,s6
    80001970:	b76d                	j	8000191a <copyinstr+0x5a>
  int got_null = 0;
    80001972:	4781                	li	a5,0
  if(got_null){
    80001974:	37fd                	addw	a5,a5,-1
    80001976:	0007851b          	sext.w	a0,a5
}
    8000197a:	8082                	ret

000000008000197c <do_rand>:
#define _RANDINT_H_
#include "types.h"
// from FreeBSD.
int
do_rand(unsigned long *ctx)
{
    8000197c:	1141                	add	sp,sp,-16
    8000197e:	e422                	sd	s0,8(sp)
    80001980:	0800                	add	s0,sp,16
 * October 1988, p. 1195.
 */
    long hi, lo, x;

    /* Transform to [1, 0x7ffffffe] range. */
    x = (*ctx % 0x7ffffffe) + 1;
    80001982:	611c                	ld	a5,0(a0)
    80001984:	80000737          	lui	a4,0x80000
    80001988:	ffe74713          	xor	a4,a4,-2
    8000198c:	02e7f7b3          	remu	a5,a5,a4
    80001990:	0785                	add	a5,a5,1
    hi = x / 127773;
    lo = x % 127773;
    80001992:	66fd                	lui	a3,0x1f
    80001994:	31d68693          	add	a3,a3,797 # 1f31d <_entry-0x7ffe0ce3>
    80001998:	02d7e733          	rem	a4,a5,a3
    x = 16807 * lo - 2836 * hi;
    8000199c:	6611                	lui	a2,0x4
    8000199e:	1a760613          	add	a2,a2,423 # 41a7 <_entry-0x7fffbe59>
    800019a2:	02c70733          	mul	a4,a4,a2
    hi = x / 127773;
    800019a6:	02d7c7b3          	div	a5,a5,a3
    x = 16807 * lo - 2836 * hi;
    800019aa:	76fd                	lui	a3,0xfffff
    800019ac:	4ec68693          	add	a3,a3,1260 # fffffffffffff4ec <end+0xffffffff7ffda444>
    800019b0:	02d787b3          	mul	a5,a5,a3
    800019b4:	97ba                	add	a5,a5,a4
    if (x < 0)
    800019b6:	0007c963          	bltz	a5,800019c8 <do_rand+0x4c>
        x += 0x7fffffff;
    /* Transform to [0, 0x7ffffffd] range. */
    x--;
    800019ba:	17fd                	add	a5,a5,-1
    *ctx = x;
    800019bc:	e11c                	sd	a5,0(a0)
    return (x);
}
    800019be:	0007851b          	sext.w	a0,a5
    800019c2:	6422                	ld	s0,8(sp)
    800019c4:	0141                	add	sp,sp,16
    800019c6:	8082                	ret
        x += 0x7fffffff;
    800019c8:	80000737          	lui	a4,0x80000
    800019cc:	fff74713          	not	a4,a4
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	b7e5                	j	800019ba <do_rand+0x3e>

00000000800019d4 <rand>:

unsigned long rand_next = 1;

int
rand(void)
{
    800019d4:	1141                	add	sp,sp,-16
    800019d6:	e406                	sd	ra,8(sp)
    800019d8:	e022                	sd	s0,0(sp)
    800019da:	0800                	add	s0,sp,16
    return (do_rand(&rand_next));
    800019dc:	00008517          	auipc	a0,0x8
    800019e0:	06c50513          	add	a0,a0,108 # 80009a48 <rand_next>
    800019e4:	00000097          	auipc	ra,0x0
    800019e8:	f98080e7          	jalr	-104(ra) # 8000197c <do_rand>
}
    800019ec:	60a2                	ld	ra,8(sp)
    800019ee:	6402                	ld	s0,0(sp)
    800019f0:	0141                	add	sp,sp,16
    800019f2:	8082                	ret

00000000800019f4 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800019f4:	7139                	add	sp,sp,-64
    800019f6:	fc06                	sd	ra,56(sp)
    800019f8:	f822                	sd	s0,48(sp)
    800019fa:	f426                	sd	s1,40(sp)
    800019fc:	f04a                	sd	s2,32(sp)
    800019fe:	ec4e                	sd	s3,24(sp)
    80001a00:	e852                	sd	s4,16(sp)
    80001a02:	e456                	sd	s5,8(sp)
    80001a04:	e05a                	sd	s6,0(sp)
    80001a06:	0080                	add	s0,sp,64
    80001a08:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a0a:	00011497          	auipc	s1,0x11
    80001a0e:	89648493          	add	s1,s1,-1898 # 800122a0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a12:	8b26                	mv	s6,s1
    80001a14:	06db7937          	lui	s2,0x6db7
    80001a18:	db790913          	add	s2,s2,-585 # 6db6db7 <_entry-0x79249249>
    80001a1c:	0932                	sll	s2,s2,0xc
    80001a1e:	db790913          	add	s2,s2,-585
    80001a22:	0932                	sll	s2,s2,0xc
    80001a24:	db790913          	add	s2,s2,-585
    80001a28:	0932                	sll	s2,s2,0xc
    80001a2a:	db790913          	add	s2,s2,-585
    80001a2e:	040009b7          	lui	s3,0x4000
    80001a32:	19fd                	add	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001a34:	09b2                	sll	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a36:	00018a97          	auipc	s5,0x18
    80001a3a:	86aa8a93          	add	s5,s5,-1942 # 800192a0 <tickslock>
    char *pa = kalloc();
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	10a080e7          	jalr	266(ra) # 80000b48 <kalloc>
    80001a46:	862a                	mv	a2,a0
    if (pa == 0)
    80001a48:	c121                	beqz	a0,80001a88 <proc_mapstacks+0x94>
    uint64 va = KSTACK((int)(p - proc));
    80001a4a:	416485b3          	sub	a1,s1,s6
    80001a4e:	8599                	sra	a1,a1,0x6
    80001a50:	032585b3          	mul	a1,a1,s2
    80001a54:	2585                	addw	a1,a1,1
    80001a56:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a5a:	4719                	li	a4,6
    80001a5c:	6685                	lui	a3,0x1
    80001a5e:	40b985b3          	sub	a1,s3,a1
    80001a62:	8552                	mv	a0,s4
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	73c080e7          	jalr	1852(ra) # 800011a0 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a6c:	1c048493          	add	s1,s1,448
    80001a70:	fd5497e3          	bne	s1,s5,80001a3e <proc_mapstacks+0x4a>
  }
}
    80001a74:	70e2                	ld	ra,56(sp)
    80001a76:	7442                	ld	s0,48(sp)
    80001a78:	74a2                	ld	s1,40(sp)
    80001a7a:	7902                	ld	s2,32(sp)
    80001a7c:	69e2                	ld	s3,24(sp)
    80001a7e:	6a42                	ld	s4,16(sp)
    80001a80:	6aa2                	ld	s5,8(sp)
    80001a82:	6b02                	ld	s6,0(sp)
    80001a84:	6121                	add	sp,sp,64
    80001a86:	8082                	ret
      panic("kalloc");
    80001a88:	00007517          	auipc	a0,0x7
    80001a8c:	73050513          	add	a0,a0,1840 # 800091b8 <etext+0x1b8>
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	ad0080e7          	jalr	-1328(ra) # 80000560 <panic>

0000000080001a98 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001a98:	7139                	add	sp,sp,-64
    80001a9a:	fc06                	sd	ra,56(sp)
    80001a9c:	f822                	sd	s0,48(sp)
    80001a9e:	f426                	sd	s1,40(sp)
    80001aa0:	f04a                	sd	s2,32(sp)
    80001aa2:	ec4e                	sd	s3,24(sp)
    80001aa4:	e852                	sd	s4,16(sp)
    80001aa6:	e456                	sd	s5,8(sp)
    80001aa8:	e05a                	sd	s6,0(sp)
    80001aaa:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001aac:	00007597          	auipc	a1,0x7
    80001ab0:	71458593          	add	a1,a1,1812 # 800091c0 <etext+0x1c0>
    80001ab4:	00010517          	auipc	a0,0x10
    80001ab8:	3bc50513          	add	a0,a0,956 # 80011e70 <pid_lock>
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	0ec080e7          	jalr	236(ra) # 80000ba8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001ac4:	00007597          	auipc	a1,0x7
    80001ac8:	70458593          	add	a1,a1,1796 # 800091c8 <etext+0x1c8>
    80001acc:	00010517          	auipc	a0,0x10
    80001ad0:	3bc50513          	add	a0,a0,956 # 80011e88 <wait_lock>
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	0d4080e7          	jalr	212(ra) # 80000ba8 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001adc:	00010497          	auipc	s1,0x10
    80001ae0:	7c448493          	add	s1,s1,1988 # 800122a0 <proc>
  {
    initlock(&p->lock, "proc");
    80001ae4:	00007b17          	auipc	s6,0x7
    80001ae8:	6f4b0b13          	add	s6,s6,1780 # 800091d8 <etext+0x1d8>
    p->state = UNUSED;
    p->trace_opt = 0; // Do not trace any syscalls by default
    p->kstack = KSTACK((int)(p - proc));
    80001aec:	8aa6                	mv	s5,s1
    80001aee:	06db7937          	lui	s2,0x6db7
    80001af2:	db790913          	add	s2,s2,-585 # 6db6db7 <_entry-0x79249249>
    80001af6:	0932                	sll	s2,s2,0xc
    80001af8:	db790913          	add	s2,s2,-585
    80001afc:	0932                	sll	s2,s2,0xc
    80001afe:	db790913          	add	s2,s2,-585
    80001b02:	0932                	sll	s2,s2,0xc
    80001b04:	db790913          	add	s2,s2,-585
    80001b08:	040009b7          	lui	s3,0x4000
    80001b0c:	19fd                	add	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001b0e:	09b2                	sll	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b10:	00017a17          	auipc	s4,0x17
    80001b14:	790a0a13          	add	s4,s4,1936 # 800192a0 <tickslock>
    initlock(&p->lock, "proc");
    80001b18:	85da                	mv	a1,s6
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	08c080e7          	jalr	140(ra) # 80000ba8 <initlock>
    p->state = UNUSED;
    80001b24:	0004ac23          	sw	zero,24(s1)
    p->trace_opt = 0; // Do not trace any syscalls by default
    80001b28:	1604a423          	sw	zero,360(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b2c:	415487b3          	sub	a5,s1,s5
    80001b30:	8799                	sra	a5,a5,0x6
    80001b32:	032787b3          	mul	a5,a5,s2
    80001b36:	2785                	addw	a5,a5,1
    80001b38:	00d7979b          	sllw	a5,a5,0xd
    80001b3c:	40f987b3          	sub	a5,s3,a5
    80001b40:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b42:	1c048493          	add	s1,s1,448
    80001b46:	fd4499e3          	bne	s1,s4,80001b18 <procinit+0x80>
  }
}
    80001b4a:	70e2                	ld	ra,56(sp)
    80001b4c:	7442                	ld	s0,48(sp)
    80001b4e:	74a2                	ld	s1,40(sp)
    80001b50:	7902                	ld	s2,32(sp)
    80001b52:	69e2                	ld	s3,24(sp)
    80001b54:	6a42                	ld	s4,16(sp)
    80001b56:	6aa2                	ld	s5,8(sp)
    80001b58:	6b02                	ld	s6,0(sp)
    80001b5a:	6121                	add	sp,sp,64
    80001b5c:	8082                	ret

0000000080001b5e <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b5e:	1141                	add	sp,sp,-16
    80001b60:	e422                	sd	s0,8(sp)
    80001b62:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b64:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b66:	2501                	sext.w	a0,a0
    80001b68:	6422                	ld	s0,8(sp)
    80001b6a:	0141                	add	sp,sp,16
    80001b6c:	8082                	ret

0000000080001b6e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b6e:	1141                	add	sp,sp,-16
    80001b70:	e422                	sd	s0,8(sp)
    80001b72:	0800                	add	s0,sp,16
    80001b74:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b76:	2781                	sext.w	a5,a5
    80001b78:	079e                	sll	a5,a5,0x7
  return c;
}
    80001b7a:	00010517          	auipc	a0,0x10
    80001b7e:	32650513          	add	a0,a0,806 # 80011ea0 <cpus>
    80001b82:	953e                	add	a0,a0,a5
    80001b84:	6422                	ld	s0,8(sp)
    80001b86:	0141                	add	sp,sp,16
    80001b88:	8082                	ret

0000000080001b8a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b8a:	1101                	add	sp,sp,-32
    80001b8c:	ec06                	sd	ra,24(sp)
    80001b8e:	e822                	sd	s0,16(sp)
    80001b90:	e426                	sd	s1,8(sp)
    80001b92:	1000                	add	s0,sp,32
  push_off();
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	058080e7          	jalr	88(ra) # 80000bec <push_off>
    80001b9c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b9e:	2781                	sext.w	a5,a5
    80001ba0:	079e                	sll	a5,a5,0x7
    80001ba2:	00010717          	auipc	a4,0x10
    80001ba6:	2ce70713          	add	a4,a4,718 # 80011e70 <pid_lock>
    80001baa:	97ba                	add	a5,a5,a4
    80001bac:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	0de080e7          	jalr	222(ra) # 80000c8c <pop_off>
  return p;
}
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	60e2                	ld	ra,24(sp)
    80001bba:	6442                	ld	s0,16(sp)
    80001bbc:	64a2                	ld	s1,8(sp)
    80001bbe:	6105                	add	sp,sp,32
    80001bc0:	8082                	ret

0000000080001bc2 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bc2:	1141                	add	sp,sp,-16
    80001bc4:	e406                	sd	ra,8(sp)
    80001bc6:	e022                	sd	s0,0(sp)
    80001bc8:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	fc0080e7          	jalr	-64(ra) # 80001b8a <myproc>
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	11a080e7          	jalr	282(ra) # 80000cec <release>

  if (first)
    80001bda:	00008797          	auipc	a5,0x8
    80001bde:	e667a783          	lw	a5,-410(a5) # 80009a40 <first.1>
    80001be2:	eb89                	bnez	a5,80001bf4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001be4:	00001097          	auipc	ra,0x1
    80001be8:	104080e7          	jalr	260(ra) # 80002ce8 <usertrapret>
}
    80001bec:	60a2                	ld	ra,8(sp)
    80001bee:	6402                	ld	s0,0(sp)
    80001bf0:	0141                	add	sp,sp,16
    80001bf2:	8082                	ret
    first = 0;
    80001bf4:	00008797          	auipc	a5,0x8
    80001bf8:	e407a623          	sw	zero,-436(a5) # 80009a40 <first.1>
    fsinit(ROOTDEV);
    80001bfc:	4505                	li	a0,1
    80001bfe:	00002097          	auipc	ra,0x2
    80001c02:	316080e7          	jalr	790(ra) # 80003f14 <fsinit>
    80001c06:	bff9                	j	80001be4 <forkret+0x22>

0000000080001c08 <allocpid>:
{
    80001c08:	1101                	add	sp,sp,-32
    80001c0a:	ec06                	sd	ra,24(sp)
    80001c0c:	e822                	sd	s0,16(sp)
    80001c0e:	e426                	sd	s1,8(sp)
    80001c10:	e04a                	sd	s2,0(sp)
    80001c12:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001c14:	00010917          	auipc	s2,0x10
    80001c18:	25c90913          	add	s2,s2,604 # 80011e70 <pid_lock>
    80001c1c:	854a                	mv	a0,s2
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	01a080e7          	jalr	26(ra) # 80000c38 <acquire>
  pid = nextpid;
    80001c26:	00008797          	auipc	a5,0x8
    80001c2a:	e1e78793          	add	a5,a5,-482 # 80009a44 <nextpid>
    80001c2e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c30:	0014871b          	addw	a4,s1,1
    80001c34:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c36:	854a                	mv	a0,s2
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	0b4080e7          	jalr	180(ra) # 80000cec <release>
}
    80001c40:	8526                	mv	a0,s1
    80001c42:	60e2                	ld	ra,24(sp)
    80001c44:	6442                	ld	s0,16(sp)
    80001c46:	64a2                	ld	s1,8(sp)
    80001c48:	6902                	ld	s2,0(sp)
    80001c4a:	6105                	add	sp,sp,32
    80001c4c:	8082                	ret

0000000080001c4e <proc_pagetable>:
{
    80001c4e:	1101                	add	sp,sp,-32
    80001c50:	ec06                	sd	ra,24(sp)
    80001c52:	e822                	sd	s0,16(sp)
    80001c54:	e426                	sd	s1,8(sp)
    80001c56:	e04a                	sd	s2,0(sp)
    80001c58:	1000                	add	s0,sp,32
    80001c5a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	73e080e7          	jalr	1854(ra) # 8000139a <uvmcreate>
    80001c64:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c66:	c121                	beqz	a0,80001ca6 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c68:	4729                	li	a4,10
    80001c6a:	00006697          	auipc	a3,0x6
    80001c6e:	39668693          	add	a3,a3,918 # 80008000 <_trampoline>
    80001c72:	6605                	lui	a2,0x1
    80001c74:	040005b7          	lui	a1,0x4000
    80001c78:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c7a:	05b2                	sll	a1,a1,0xc
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	484080e7          	jalr	1156(ra) # 80001100 <mappages>
    80001c84:	02054863          	bltz	a0,80001cb4 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c88:	4719                	li	a4,6
    80001c8a:	05893683          	ld	a3,88(s2)
    80001c8e:	6605                	lui	a2,0x1
    80001c90:	020005b7          	lui	a1,0x2000
    80001c94:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c96:	05b6                	sll	a1,a1,0xd
    80001c98:	8526                	mv	a0,s1
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	466080e7          	jalr	1126(ra) # 80001100 <mappages>
    80001ca2:	02054163          	bltz	a0,80001cc4 <proc_pagetable+0x76>
}
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	60e2                	ld	ra,24(sp)
    80001caa:	6442                	ld	s0,16(sp)
    80001cac:	64a2                	ld	s1,8(sp)
    80001cae:	6902                	ld	s2,0(sp)
    80001cb0:	6105                	add	sp,sp,32
    80001cb2:	8082                	ret
    uvmfree(pagetable, 0);
    80001cb4:	4581                	li	a1,0
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	8f4080e7          	jalr	-1804(ra) # 800015ac <uvmfree>
    return 0;
    80001cc0:	4481                	li	s1,0
    80001cc2:	b7d5                	j	80001ca6 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cc4:	4681                	li	a3,0
    80001cc6:	4605                	li	a2,1
    80001cc8:	040005b7          	lui	a1,0x4000
    80001ccc:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cce:	05b2                	sll	a1,a1,0xc
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	5f4080e7          	jalr	1524(ra) # 800012c6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001cda:	4581                	li	a1,0
    80001cdc:	8526                	mv	a0,s1
    80001cde:	00000097          	auipc	ra,0x0
    80001ce2:	8ce080e7          	jalr	-1842(ra) # 800015ac <uvmfree>
    return 0;
    80001ce6:	4481                	li	s1,0
    80001ce8:	bf7d                	j	80001ca6 <proc_pagetable+0x58>

0000000080001cea <proc_freepagetable>:
{
    80001cea:	1101                	add	sp,sp,-32
    80001cec:	ec06                	sd	ra,24(sp)
    80001cee:	e822                	sd	s0,16(sp)
    80001cf0:	e426                	sd	s1,8(sp)
    80001cf2:	e04a                	sd	s2,0(sp)
    80001cf4:	1000                	add	s0,sp,32
    80001cf6:	84aa                	mv	s1,a0
    80001cf8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cfa:	4681                	li	a3,0
    80001cfc:	4605                	li	a2,1
    80001cfe:	040005b7          	lui	a1,0x4000
    80001d02:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d04:	05b2                	sll	a1,a1,0xc
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	5c0080e7          	jalr	1472(ra) # 800012c6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d0e:	4681                	li	a3,0
    80001d10:	4605                	li	a2,1
    80001d12:	020005b7          	lui	a1,0x2000
    80001d16:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d18:	05b6                	sll	a1,a1,0xd
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	5aa080e7          	jalr	1450(ra) # 800012c6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d24:	85ca                	mv	a1,s2
    80001d26:	8526                	mv	a0,s1
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	884080e7          	jalr	-1916(ra) # 800015ac <uvmfree>
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6902                	ld	s2,0(sp)
    80001d38:	6105                	add	sp,sp,32
    80001d3a:	8082                	ret

0000000080001d3c <freeproc>:
{
    80001d3c:	1101                	add	sp,sp,-32
    80001d3e:	ec06                	sd	ra,24(sp)
    80001d40:	e822                	sd	s0,16(sp)
    80001d42:	e426                	sd	s1,8(sp)
    80001d44:	1000                	add	s0,sp,32
    80001d46:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d48:	6d28                	ld	a0,88(a0)
    80001d4a:	c509                	beqz	a0,80001d54 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	cfe080e7          	jalr	-770(ra) # 80000a4a <kfree>
  p->trapframe = 0;
    80001d54:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d58:	68a8                	ld	a0,80(s1)
    80001d5a:	c511                	beqz	a0,80001d66 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d5c:	64ac                	ld	a1,72(s1)
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	f8c080e7          	jalr	-116(ra) # 80001cea <proc_freepagetable>
  p->pagetable = 0;
    80001d66:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d6a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d6e:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d72:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d76:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d7a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d7e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d82:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d86:	0004ac23          	sw	zero,24(s1)
  p->trace_opt = 0;
    80001d8a:	1604a423          	sw	zero,360(s1)
  p->creation_time = 0;
    80001d8e:	1804a823          	sw	zero,400(s1)
  p->run_time = 0;
    80001d92:	1804aa23          	sw	zero,404(s1)
  p->exit_time = 0;
    80001d96:	1804ac23          	sw	zero,408(s1)
  p->sleep_time = 0;
    80001d9a:	1804ae23          	sw	zero,412(s1)
  p->num_scheduled = 0;
    80001d9e:	1a04a023          	sw	zero,416(s1)
  p->static_priority = 0;
    80001da2:	1a04a223          	sw	zero,420(s1)
  p->niceness = 0;
    80001da6:	1a04a423          	sw	zero,424(s1)
  p->wait_time = 0;
    80001daa:	1a04a623          	sw	zero,428(s1)
  p->is_in_queue = 0;
    80001dae:	1a04a823          	sw	zero,432(s1)
  p->queue_num = 0;
    80001db2:	1a04aa23          	sw	zero,436(s1)
  p->curr_run_time = 0;
    80001db6:	1a04ac23          	sw	zero,440(s1)
}
    80001dba:	60e2                	ld	ra,24(sp)
    80001dbc:	6442                	ld	s0,16(sp)
    80001dbe:	64a2                	ld	s1,8(sp)
    80001dc0:	6105                	add	sp,sp,32
    80001dc2:	8082                	ret

0000000080001dc4 <allocproc>:
{
    80001dc4:	1101                	add	sp,sp,-32
    80001dc6:	ec06                	sd	ra,24(sp)
    80001dc8:	e822                	sd	s0,16(sp)
    80001dca:	e426                	sd	s1,8(sp)
    80001dcc:	e04a                	sd	s2,0(sp)
    80001dce:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001dd0:	00010497          	auipc	s1,0x10
    80001dd4:	4d048493          	add	s1,s1,1232 # 800122a0 <proc>
    80001dd8:	00017917          	auipc	s2,0x17
    80001ddc:	4c890913          	add	s2,s2,1224 # 800192a0 <tickslock>
    acquire(&p->lock);
    80001de0:	8526                	mv	a0,s1
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	e56080e7          	jalr	-426(ra) # 80000c38 <acquire>
    if (p->state == UNUSED)
    80001dea:	4c9c                	lw	a5,24(s1)
    80001dec:	cf81                	beqz	a5,80001e04 <allocproc+0x40>
      release(&p->lock);
    80001dee:	8526                	mv	a0,s1
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	efc080e7          	jalr	-260(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001df8:	1c048493          	add	s1,s1,448
    80001dfc:	ff2492e3          	bne	s1,s2,80001de0 <allocproc+0x1c>
  return 0;
    80001e00:	4481                	li	s1,0
    80001e02:	a071                	j	80001e8e <allocproc+0xca>
  p->pid = allocpid();
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	e04080e7          	jalr	-508(ra) # 80001c08 <allocpid>
    80001e0c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e0e:	4785                	li	a5,1
    80001e10:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	d36080e7          	jalr	-714(ra) # 80000b48 <kalloc>
    80001e1a:	892a                	mv	s2,a0
    80001e1c:	eca8                	sd	a0,88(s1)
    80001e1e:	cd3d                	beqz	a0,80001e9c <allocproc+0xd8>
  p->pagetable = proc_pagetable(p);
    80001e20:	8526                	mv	a0,s1
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	e2c080e7          	jalr	-468(ra) # 80001c4e <proc_pagetable>
    80001e2a:	892a                	mv	s2,a0
    80001e2c:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001e2e:	c159                	beqz	a0,80001eb4 <allocproc+0xf0>
  memset(&p->context, 0, sizeof(p->context));
    80001e30:	07000613          	li	a2,112
    80001e34:	4581                	li	a1,0
    80001e36:	06048513          	add	a0,s1,96
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	efa080e7          	jalr	-262(ra) # 80000d34 <memset>
  p->context.ra = (uint64)forkret;
    80001e42:	00000797          	auipc	a5,0x0
    80001e46:	d8078793          	add	a5,a5,-640 # 80001bc2 <forkret>
    80001e4a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e4c:	60bc                	ld	a5,64(s1)
    80001e4e:	6705                	lui	a4,0x1
    80001e50:	97ba                	add	a5,a5,a4
    80001e52:	f4bc                	sd	a5,104(s1)
  p->creation_time = ticks; // Creation time of the process in ticks
    80001e54:	00008797          	auipc	a5,0x8
    80001e58:	dac7a783          	lw	a5,-596(a5) # 80009c00 <ticks>
    80001e5c:	18f4a823          	sw	a5,400(s1)
  p->run_time = 0;
    80001e60:	1804aa23          	sw	zero,404(s1)
  p->exit_time = 0;
    80001e64:	1804ac23          	sw	zero,408(s1)
  p->sleep_time = 0;
    80001e68:	1804ae23          	sw	zero,412(s1)
  p->num_scheduled = 0;
    80001e6c:	1a04a023          	sw	zero,416(s1)
  p->static_priority = 60;
    80001e70:	03c00793          	li	a5,60
    80001e74:	1af4a223          	sw	a5,420(s1)
  p->niceness = 5;
    80001e78:	4795                	li	a5,5
    80001e7a:	1af4a423          	sw	a5,424(s1)
  p->wait_time = 0;
    80001e7e:	1a04a623          	sw	zero,428(s1)
  p->is_in_queue = 0;
    80001e82:	1a04a823          	sw	zero,432(s1)
  p->queue_num = 0;
    80001e86:	1a04aa23          	sw	zero,436(s1)
  p->curr_run_time = 0;
    80001e8a:	1a04ac23          	sw	zero,440(s1)
}
    80001e8e:	8526                	mv	a0,s1
    80001e90:	60e2                	ld	ra,24(sp)
    80001e92:	6442                	ld	s0,16(sp)
    80001e94:	64a2                	ld	s1,8(sp)
    80001e96:	6902                	ld	s2,0(sp)
    80001e98:	6105                	add	sp,sp,32
    80001e9a:	8082                	ret
    freeproc(p);
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	e9e080e7          	jalr	-354(ra) # 80001d3c <freeproc>
    release(&p->lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	e44080e7          	jalr	-444(ra) # 80000cec <release>
    return 0;
    80001eb0:	84ca                	mv	s1,s2
    80001eb2:	bff1                	j	80001e8e <allocproc+0xca>
    freeproc(p);
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	00000097          	auipc	ra,0x0
    80001eba:	e86080e7          	jalr	-378(ra) # 80001d3c <freeproc>
    release(&p->lock);
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	e2c080e7          	jalr	-468(ra) # 80000cec <release>
    return 0;
    80001ec8:	84ca                	mv	s1,s2
    80001eca:	b7d1                	j	80001e8e <allocproc+0xca>

0000000080001ecc <userinit>:
{
    80001ecc:	1101                	add	sp,sp,-32
    80001ece:	ec06                	sd	ra,24(sp)
    80001ed0:	e822                	sd	s0,16(sp)
    80001ed2:	e426                	sd	s1,8(sp)
    80001ed4:	1000                	add	s0,sp,32
  p = allocproc();
    80001ed6:	00000097          	auipc	ra,0x0
    80001eda:	eee080e7          	jalr	-274(ra) # 80001dc4 <allocproc>
    80001ede:	84aa                	mv	s1,a0
  initproc = p;
    80001ee0:	00008797          	auipc	a5,0x8
    80001ee4:	d0a7bc23          	sd	a0,-744(a5) # 80009bf8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ee8:	03400613          	li	a2,52
    80001eec:	00008597          	auipc	a1,0x8
    80001ef0:	b6458593          	add	a1,a1,-1180 # 80009a50 <initcode>
    80001ef4:	6928                	ld	a0,80(a0)
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	4d2080e7          	jalr	1234(ra) # 800013c8 <uvmfirst>
  p->sz = PGSIZE;
    80001efe:	6785                	lui	a5,0x1
    80001f00:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001f02:	6cb8                	ld	a4,88(s1)
    80001f04:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001f08:	6cb8                	ld	a4,88(s1)
    80001f0a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f0c:	4641                	li	a2,16
    80001f0e:	00007597          	auipc	a1,0x7
    80001f12:	2d258593          	add	a1,a1,722 # 800091e0 <etext+0x1e0>
    80001f16:	15848513          	add	a0,s1,344
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	f5c080e7          	jalr	-164(ra) # 80000e76 <safestrcpy>
  p->cwd = namei("/");
    80001f22:	00007517          	auipc	a0,0x7
    80001f26:	2ce50513          	add	a0,a0,718 # 800091f0 <etext+0x1f0>
    80001f2a:	00003097          	auipc	ra,0x3
    80001f2e:	a3c080e7          	jalr	-1476(ra) # 80004966 <namei>
    80001f32:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f36:	478d                	li	a5,3
    80001f38:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	db0080e7          	jalr	-592(ra) # 80000cec <release>
}
    80001f44:	60e2                	ld	ra,24(sp)
    80001f46:	6442                	ld	s0,16(sp)
    80001f48:	64a2                	ld	s1,8(sp)
    80001f4a:	6105                	add	sp,sp,32
    80001f4c:	8082                	ret

0000000080001f4e <growproc>:
{
    80001f4e:	1101                	add	sp,sp,-32
    80001f50:	ec06                	sd	ra,24(sp)
    80001f52:	e822                	sd	s0,16(sp)
    80001f54:	e426                	sd	s1,8(sp)
    80001f56:	e04a                	sd	s2,0(sp)
    80001f58:	1000                	add	s0,sp,32
    80001f5a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	c2e080e7          	jalr	-978(ra) # 80001b8a <myproc>
    80001f64:	84aa                	mv	s1,a0
  sz = p->sz;
    80001f66:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001f68:	01204c63          	bgtz	s2,80001f80 <growproc+0x32>
  else if (n < 0)
    80001f6c:	02094663          	bltz	s2,80001f98 <growproc+0x4a>
  p->sz = sz;
    80001f70:	e4ac                	sd	a1,72(s1)
  return 0;
    80001f72:	4501                	li	a0,0
}
    80001f74:	60e2                	ld	ra,24(sp)
    80001f76:	6442                	ld	s0,16(sp)
    80001f78:	64a2                	ld	s1,8(sp)
    80001f7a:	6902                	ld	s2,0(sp)
    80001f7c:	6105                	add	sp,sp,32
    80001f7e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f80:	4691                	li	a3,4
    80001f82:	00b90633          	add	a2,s2,a1
    80001f86:	6928                	ld	a0,80(a0)
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	4fa080e7          	jalr	1274(ra) # 80001482 <uvmalloc>
    80001f90:	85aa                	mv	a1,a0
    80001f92:	fd79                	bnez	a0,80001f70 <growproc+0x22>
      return -1;
    80001f94:	557d                	li	a0,-1
    80001f96:	bff9                	j	80001f74 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f98:	00b90633          	add	a2,s2,a1
    80001f9c:	6928                	ld	a0,80(a0)
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	49c080e7          	jalr	1180(ra) # 8000143a <uvmdealloc>
    80001fa6:	85aa                	mv	a1,a0
    80001fa8:	b7e1                	j	80001f70 <growproc+0x22>

0000000080001faa <fork>:
{
    80001faa:	7139                	add	sp,sp,-64
    80001fac:	fc06                	sd	ra,56(sp)
    80001fae:	f822                	sd	s0,48(sp)
    80001fb0:	f04a                	sd	s2,32(sp)
    80001fb2:	e456                	sd	s5,8(sp)
    80001fb4:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	bd4080e7          	jalr	-1068(ra) # 80001b8a <myproc>
    80001fbe:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	e04080e7          	jalr	-508(ra) # 80001dc4 <allocproc>
    80001fc8:	12050463          	beqz	a0,800020f0 <fork+0x146>
    80001fcc:	ec4e                	sd	s3,24(sp)
    80001fce:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001fd0:	048ab603          	ld	a2,72(s5)
    80001fd4:	692c                	ld	a1,80(a0)
    80001fd6:	050ab503          	ld	a0,80(s5)
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	60c080e7          	jalr	1548(ra) # 800015e6 <uvmcopy>
    80001fe2:	04054e63          	bltz	a0,8000203e <fork+0x94>
    80001fe6:	f426                	sd	s1,40(sp)
    80001fe8:	e852                	sd	s4,16(sp)
  np->sz = p->sz;
    80001fea:	048ab783          	ld	a5,72(s5)
    80001fee:	04f9b423          	sd	a5,72(s3)
  np->trace_opt = p->trace_opt;
    80001ff2:	168aa783          	lw	a5,360(s5)
    80001ff6:	16f9a423          	sw	a5,360(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ffa:	058ab683          	ld	a3,88(s5)
    80001ffe:	87b6                	mv	a5,a3
    80002000:	0589b703          	ld	a4,88(s3)
    80002004:	12068693          	add	a3,a3,288
    80002008:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000200c:	6788                	ld	a0,8(a5)
    8000200e:	6b8c                	ld	a1,16(a5)
    80002010:	6f90                	ld	a2,24(a5)
    80002012:	01073023          	sd	a6,0(a4)
    80002016:	e708                	sd	a0,8(a4)
    80002018:	eb0c                	sd	a1,16(a4)
    8000201a:	ef10                	sd	a2,24(a4)
    8000201c:	02078793          	add	a5,a5,32
    80002020:	02070713          	add	a4,a4,32
    80002024:	fed792e3          	bne	a5,a3,80002008 <fork+0x5e>
  np->trapframe->a0 = 0;
    80002028:	0589b783          	ld	a5,88(s3)
    8000202c:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80002030:	0d0a8493          	add	s1,s5,208
    80002034:	0d098913          	add	s2,s3,208
    80002038:	150a8a13          	add	s4,s5,336
    8000203c:	a015                	j	80002060 <fork+0xb6>
    freeproc(np);
    8000203e:	854e                	mv	a0,s3
    80002040:	00000097          	auipc	ra,0x0
    80002044:	cfc080e7          	jalr	-772(ra) # 80001d3c <freeproc>
    release(&np->lock);
    80002048:	854e                	mv	a0,s3
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	ca2080e7          	jalr	-862(ra) # 80000cec <release>
    return -1;
    80002052:	597d                	li	s2,-1
    80002054:	69e2                	ld	s3,24(sp)
    80002056:	a071                	j	800020e2 <fork+0x138>
  for (i = 0; i < NOFILE; i++)
    80002058:	04a1                	add	s1,s1,8
    8000205a:	0921                	add	s2,s2,8
    8000205c:	01448b63          	beq	s1,s4,80002072 <fork+0xc8>
    if (p->ofile[i])
    80002060:	6088                	ld	a0,0(s1)
    80002062:	d97d                	beqz	a0,80002058 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    80002064:	00003097          	auipc	ra,0x3
    80002068:	f7a080e7          	jalr	-134(ra) # 80004fde <filedup>
    8000206c:	00a93023          	sd	a0,0(s2)
    80002070:	b7e5                	j	80002058 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002072:	150ab503          	ld	a0,336(s5)
    80002076:	00002097          	auipc	ra,0x2
    8000207a:	0e4080e7          	jalr	228(ra) # 8000415a <idup>
    8000207e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002082:	4641                	li	a2,16
    80002084:	158a8593          	add	a1,s5,344
    80002088:	15898513          	add	a0,s3,344
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	dea080e7          	jalr	-534(ra) # 80000e76 <safestrcpy>
  pid = np->pid;
    80002094:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80002098:	854e                	mv	a0,s3
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	c52080e7          	jalr	-942(ra) # 80000cec <release>
  acquire(&wait_lock);
    800020a2:	00010497          	auipc	s1,0x10
    800020a6:	de648493          	add	s1,s1,-538 # 80011e88 <wait_lock>
    800020aa:	8526                	mv	a0,s1
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	b8c080e7          	jalr	-1140(ra) # 80000c38 <acquire>
  np->parent = p;
    800020b4:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	c32080e7          	jalr	-974(ra) # 80000cec <release>
  acquire(&np->lock);
    800020c2:	854e                	mv	a0,s3
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b74080e7          	jalr	-1164(ra) # 80000c38 <acquire>
  np->state = RUNNABLE;
    800020cc:	478d                	li	a5,3
    800020ce:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800020d2:	854e                	mv	a0,s3
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	c18080e7          	jalr	-1000(ra) # 80000cec <release>
  return pid;
    800020dc:	74a2                	ld	s1,40(sp)
    800020de:	69e2                	ld	s3,24(sp)
    800020e0:	6a42                	ld	s4,16(sp)
}
    800020e2:	854a                	mv	a0,s2
    800020e4:	70e2                	ld	ra,56(sp)
    800020e6:	7442                	ld	s0,48(sp)
    800020e8:	7902                	ld	s2,32(sp)
    800020ea:	6aa2                	ld	s5,8(sp)
    800020ec:	6121                	add	sp,sp,64
    800020ee:	8082                	ret
    return -1;
    800020f0:	597d                	li	s2,-1
    800020f2:	bfc5                	j	800020e2 <fork+0x138>

00000000800020f4 <timer_update>:
{
    800020f4:	7139                	add	sp,sp,-64
    800020f6:	fc06                	sd	ra,56(sp)
    800020f8:	f822                	sd	s0,48(sp)
    800020fa:	f426                	sd	s1,40(sp)
    800020fc:	f04a                	sd	s2,32(sp)
    800020fe:	ec4e                	sd	s3,24(sp)
    80002100:	e852                	sd	s4,16(sp)
    80002102:	e456                	sd	s5,8(sp)
    80002104:	0080                	add	s0,sp,64
  for (p = proc; p < &proc[NPROC]; p++) {
    80002106:	00010497          	auipc	s1,0x10
    8000210a:	19a48493          	add	s1,s1,410 # 800122a0 <proc>
    if (p->state == RUNNING) {
    8000210e:	4991                	li	s3,4
    else if (p->state == SLEEPING) {
    80002110:	4a09                	li	s4,2
    else if (p->state == RUNNABLE) {
    80002112:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++) {
    80002114:	00017917          	auipc	s2,0x17
    80002118:	18c90913          	add	s2,s2,396 # 800192a0 <tickslock>
    8000211c:	a839                	j	8000213a <timer_update+0x46>
      p->run_time++;
    8000211e:	1944a783          	lw	a5,404(s1)
    80002122:	2785                	addw	a5,a5,1
    80002124:	18f4aa23          	sw	a5,404(s1)
    release(&p->lock); 
    80002128:	8526                	mv	a0,s1
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	bc2080e7          	jalr	-1086(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002132:	1c048493          	add	s1,s1,448
    80002136:	03248f63          	beq	s1,s2,80002174 <timer_update+0x80>
    acquire(&p->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	afc080e7          	jalr	-1284(ra) # 80000c38 <acquire>
    if (p->state == RUNNING) {
    80002144:	4c9c                	lw	a5,24(s1)
    80002146:	fd378ce3          	beq	a5,s3,8000211e <timer_update+0x2a>
    else if (p->state == SLEEPING) {
    8000214a:	01478a63          	beq	a5,s4,8000215e <timer_update+0x6a>
    else if (p->state == RUNNABLE) {
    8000214e:	fd579de3          	bne	a5,s5,80002128 <timer_update+0x34>
      p->wait_time++;
    80002152:	1ac4a783          	lw	a5,428(s1)
    80002156:	2785                	addw	a5,a5,1
    80002158:	1af4a623          	sw	a5,428(s1)
    8000215c:	b7f1                	j	80002128 <timer_update+0x34>
      p->sleep_time++;
    8000215e:	19c4a783          	lw	a5,412(s1)
    80002162:	2785                	addw	a5,a5,1
    80002164:	18f4ae23          	sw	a5,412(s1)
      p->wait_time++;
    80002168:	1ac4a783          	lw	a5,428(s1)
    8000216c:	2785                	addw	a5,a5,1
    8000216e:	1af4a623          	sw	a5,428(s1)
    80002172:	bf5d                	j	80002128 <timer_update+0x34>
}
    80002174:	70e2                	ld	ra,56(sp)
    80002176:	7442                	ld	s0,48(sp)
    80002178:	74a2                	ld	s1,40(sp)
    8000217a:	7902                	ld	s2,32(sp)
    8000217c:	69e2                	ld	s3,24(sp)
    8000217e:	6a42                	ld	s4,16(sp)
    80002180:	6aa2                	ld	s5,8(sp)
    80002182:	6121                	add	sp,sp,64
    80002184:	8082                	ret

0000000080002186 <dynamic_priority>:
{
    80002186:	1141                	add	sp,sp,-16
    80002188:	e422                	sd	s0,8(sp)
    8000218a:	0800                	add	s0,sp,16
  if (p->run_time > 0) // if the process has already run, update niceness else default 5 remains
    8000218c:	19452783          	lw	a5,404(a0)
    80002190:	cf89                	beqz	a5,800021aa <dynamic_priority+0x24>
    p->niceness = (p->run_time / (p->run_time + p->sleep_time)) * 10;
    80002192:	19c52703          	lw	a4,412(a0)
    80002196:	9f3d                	addw	a4,a4,a5
    80002198:	02e7d7bb          	divuw	a5,a5,a4
    8000219c:	0027971b          	sllw	a4,a5,0x2
    800021a0:	9fb9                	addw	a5,a5,a4
    800021a2:	0017979b          	sllw	a5,a5,0x1
    800021a6:	1af52423          	sw	a5,424(a0)
  int dp = p->static_priority - p->niceness + 5;
    800021aa:	1a452783          	lw	a5,420(a0)
    800021ae:	1a852703          	lw	a4,424(a0)
    800021b2:	9f99                	subw	a5,a5,a4
    800021b4:	2795                	addw	a5,a5,5
  dp = 100 > dp ? dp : 100;
    800021b6:	853e                	mv	a0,a5
    800021b8:	2781                	sext.w	a5,a5
    800021ba:	06400713          	li	a4,100
    800021be:	00f75463          	bge	a4,a5,800021c6 <dynamic_priority+0x40>
    800021c2:	06400513          	li	a0,100
  dp = 0 > dp ? 0 : dp;
    800021c6:	0005079b          	sext.w	a5,a0
    800021ca:	fff7c793          	not	a5,a5
    800021ce:	97fd                	sra	a5,a5,0x3f
    800021d0:	8d7d                	and	a0,a0,a5
}
    800021d2:	2501                	sext.w	a0,a0
    800021d4:	6422                	ld	s0,8(sp)
    800021d6:	0141                	add	sp,sp,16
    800021d8:	8082                	ret

00000000800021da <scheduler>:
{
    800021da:	7159                	add	sp,sp,-112
    800021dc:	f486                	sd	ra,104(sp)
    800021de:	f0a2                	sd	s0,96(sp)
    800021e0:	eca6                	sd	s1,88(sp)
    800021e2:	e8ca                	sd	s2,80(sp)
    800021e4:	e4ce                	sd	s3,72(sp)
    800021e6:	e0d2                	sd	s4,64(sp)
    800021e8:	fc56                	sd	s5,56(sp)
    800021ea:	f85a                	sd	s6,48(sp)
    800021ec:	f45e                	sd	s7,40(sp)
    800021ee:	f062                	sd	s8,32(sp)
    800021f0:	ec66                	sd	s9,24(sp)
    800021f2:	e86a                	sd	s10,16(sp)
    800021f4:	e46e                	sd	s11,8(sp)
    800021f6:	1880                	add	s0,sp,112
    800021f8:	8792                	mv	a5,tp
  int id = r_tp();
    800021fa:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021fc:	00779693          	sll	a3,a5,0x7
    80002200:	00010717          	auipc	a4,0x10
    80002204:	c7070713          	add	a4,a4,-912 # 80011e70 <pid_lock>
    80002208:	9736                	add	a4,a4,a3
    8000220a:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    8000220e:	00010717          	auipc	a4,0x10
    80002212:	c9a70713          	add	a4,a4,-870 # 80011ea8 <cpus+0x8>
    80002216:	00e68db3          	add	s11,a3,a4
      if (p->state == RUNNABLE && p->is_in_queue == 0 && mlfq_queue.proc_queue_size[0] != NPROC - 1) // new process, push to queue
    8000221a:	4a0d                	li	s4,3
    8000221c:	00023b17          	auipc	s6,0x23
    80002220:	464b0b13          	add	s6,s6,1124 # 80025680 <end+0x5d8>
    for (p = proc; p < &proc[NPROC]; p++)
    80002224:	00017917          	auipc	s2,0x17
    80002228:	07c90913          	add	s2,s2,124 # 800192a0 <tickslock>
          c->proc = p;
    8000222c:	00010c17          	auipc	s8,0x10
    80002230:	c44c0c13          	add	s8,s8,-956 # 80011e70 <pid_lock>
    80002234:	9c36                	add	s8,s8,a3
    80002236:	a0c5                	j	80002316 <scheduler+0x13c>
          remove_process(p->queue_num, p);
    80002238:	85a6                	mv	a1,s1
    8000223a:	00005097          	auipc	ra,0x5
    8000223e:	c96080e7          	jalr	-874(ra) # 80006ed0 <remove_process>
          enque(p->queue_num - 1, p);
    80002242:	1b44a503          	lw	a0,436(s1)
    80002246:	85a6                	mv	a1,s1
    80002248:	357d                	addw	a0,a0,-1
    8000224a:	00005097          	auipc	ra,0x5
    8000224e:	c1a080e7          	jalr	-998(ra) # 80006e64 <enque>
    80002252:	a82d                	j	8000228c <scheduler+0xb2>
      if (p->state == RUNNABLE && p->is_in_queue == 0 && mlfq_queue.proc_queue_size[0] != NPROC - 1) // new process, push to queue
    80002254:	4c9c                	lw	a5,24(s1)
    80002256:	05478163          	beq	a5,s4,80002298 <scheduler+0xbe>
      release(&p->lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	a90080e7          	jalr	-1392(ra) # 80000cec <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002264:	1c048493          	add	s1,s1,448
    80002268:	05248663          	beq	s1,s2,800022b4 <scheduler+0xda>
      acquire(&p->lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	9ca080e7          	jalr	-1590(ra) # 80000c38 <acquire>
      if (p->wait_time > AGETIME && p->is_in_queue == 1) // check if process has to be aged
    80002276:	1ac4a783          	lw	a5,428(s1)
    8000227a:	fcf9fde3          	bgeu	s3,a5,80002254 <scheduler+0x7a>
    8000227e:	1b04a783          	lw	a5,432(s1)
    80002282:	fd5799e3          	bne	a5,s5,80002254 <scheduler+0x7a>
        if (p->queue_num != 0)
    80002286:	1b44a503          	lw	a0,436(s1)
    8000228a:	f55d                	bnez	a0,80002238 <scheduler+0x5e>
        release(&p->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	a5e080e7          	jalr	-1442(ra) # 80000cec <release>
        continue;
    80002296:	b7f9                	j	80002264 <scheduler+0x8a>
      if (p->state == RUNNABLE && p->is_in_queue == 0 && mlfq_queue.proc_queue_size[0] != NPROC - 1) // new process, push to queue
    80002298:	1b04a783          	lw	a5,432(s1)
    8000229c:	ffdd                	bnez	a5,8000225a <scheduler+0x80>
    8000229e:	a00b2783          	lw	a5,-1536(s6)
    800022a2:	fb778ce3          	beq	a5,s7,8000225a <scheduler+0x80>
        enque(0, p);
    800022a6:	85a6                	mv	a1,s1
    800022a8:	4501                	li	a0,0
    800022aa:	00005097          	auipc	ra,0x5
    800022ae:	bba080e7          	jalr	-1094(ra) # 80006e64 <enque>
    800022b2:	b765                	j	8000225a <scheduler+0x80>
    800022b4:	00023a97          	auipc	s5,0x23
    800022b8:	dcca8a93          	add	s5,s5,-564 # 80025080 <mlfq_queue+0xa00>
    for (int i = 0; i < 5; i++)
    800022bc:	4481                	li	s1,0
    800022be:	4c95                	li	s9,5
    800022c0:	a029                	j	800022ca <scheduler+0xf0>
    800022c2:	2485                	addw	s1,s1,1
    800022c4:	0a91                	add	s5,s5,4
    800022c6:	05948b63          	beq	s1,s9,8000231c <scheduler+0x142>
      if (mlfq_queue.proc_queue_size[i] != 0)
    800022ca:	000aa783          	lw	a5,0(s5)
    800022ce:	dbf5                	beqz	a5,800022c2 <scheduler+0xe8>
        p = remove_first(i);
    800022d0:	8526                	mv	a0,s1
    800022d2:	00005097          	auipc	ra,0x5
    800022d6:	cc4080e7          	jalr	-828(ra) # 80006f96 <remove_first>
    800022da:	8d2a                	mv	s10,a0
        if (p != 0)
    800022dc:	d17d                	beqz	a0,800022c2 <scheduler+0xe8>
          acquire(&p->lock);
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	95a080e7          	jalr	-1702(ra) # 80000c38 <acquire>
          p->state = RUNNING;
    800022e6:	4791                	li	a5,4
    800022e8:	00fd2c23          	sw	a5,24(s10)
          p->num_scheduled++;
    800022ec:	1a0d2783          	lw	a5,416(s10)
    800022f0:	2785                	addw	a5,a5,1
    800022f2:	1afd2023          	sw	a5,416(s10)
          c->proc = p;
    800022f6:	03ac3823          	sd	s10,48(s8)
          swtch(&c->context, &p->context);
    800022fa:	060d0593          	add	a1,s10,96
    800022fe:	856e                	mv	a0,s11
    80002300:	00001097          	auipc	ra,0x1
    80002304:	93e080e7          	jalr	-1730(ra) # 80002c3e <swtch>
          c->proc = 0;
    80002308:	020c3823          	sd	zero,48(s8)
          release(&p->lock);
    8000230c:	856a                	mv	a0,s10
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	9de080e7          	jalr	-1570(ra) # 80000cec <release>
      if (p->wait_time > AGETIME && p->is_in_queue == 1) // check if process has to be aged
    80002316:	49f9                	li	s3,30
      if (p->state == RUNNABLE && p->is_in_queue == 0 && mlfq_queue.proc_queue_size[0] != NPROC - 1) // new process, push to queue
    80002318:	03f00b93          	li	s7,63
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000231c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002320:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002324:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002328:	00010497          	auipc	s1,0x10
    8000232c:	f7848493          	add	s1,s1,-136 # 800122a0 <proc>
      if (p->wait_time > AGETIME && p->is_in_queue == 1) // check if process has to be aged
    80002330:	4a85                	li	s5,1
    80002332:	bf2d                	j	8000226c <scheduler+0x92>

0000000080002334 <sched>:
{
    80002334:	7179                	add	sp,sp,-48
    80002336:	f406                	sd	ra,40(sp)
    80002338:	f022                	sd	s0,32(sp)
    8000233a:	ec26                	sd	s1,24(sp)
    8000233c:	e84a                	sd	s2,16(sp)
    8000233e:	e44e                	sd	s3,8(sp)
    80002340:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    80002342:	00000097          	auipc	ra,0x0
    80002346:	848080e7          	jalr	-1976(ra) # 80001b8a <myproc>
    8000234a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	872080e7          	jalr	-1934(ra) # 80000bbe <holding>
    80002354:	c93d                	beqz	a0,800023ca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002356:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002358:	2781                	sext.w	a5,a5
    8000235a:	079e                	sll	a5,a5,0x7
    8000235c:	00010717          	auipc	a4,0x10
    80002360:	b1470713          	add	a4,a4,-1260 # 80011e70 <pid_lock>
    80002364:	97ba                	add	a5,a5,a4
    80002366:	0a87a703          	lw	a4,168(a5)
    8000236a:	4785                	li	a5,1
    8000236c:	06f71763          	bne	a4,a5,800023da <sched+0xa6>
  if (p->state == RUNNING)
    80002370:	4c98                	lw	a4,24(s1)
    80002372:	4791                	li	a5,4
    80002374:	06f70b63          	beq	a4,a5,800023ea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002378:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000237c:	8b89                	and	a5,a5,2
  if (intr_get())
    8000237e:	efb5                	bnez	a5,800023fa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002380:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002382:	00010917          	auipc	s2,0x10
    80002386:	aee90913          	add	s2,s2,-1298 # 80011e70 <pid_lock>
    8000238a:	2781                	sext.w	a5,a5
    8000238c:	079e                	sll	a5,a5,0x7
    8000238e:	97ca                	add	a5,a5,s2
    80002390:	0ac7a983          	lw	s3,172(a5)
    80002394:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002396:	2781                	sext.w	a5,a5
    80002398:	079e                	sll	a5,a5,0x7
    8000239a:	00010597          	auipc	a1,0x10
    8000239e:	b0e58593          	add	a1,a1,-1266 # 80011ea8 <cpus+0x8>
    800023a2:	95be                	add	a1,a1,a5
    800023a4:	06048513          	add	a0,s1,96
    800023a8:	00001097          	auipc	ra,0x1
    800023ac:	896080e7          	jalr	-1898(ra) # 80002c3e <swtch>
    800023b0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023b2:	2781                	sext.w	a5,a5
    800023b4:	079e                	sll	a5,a5,0x7
    800023b6:	993e                	add	s2,s2,a5
    800023b8:	0b392623          	sw	s3,172(s2)
}
    800023bc:	70a2                	ld	ra,40(sp)
    800023be:	7402                	ld	s0,32(sp)
    800023c0:	64e2                	ld	s1,24(sp)
    800023c2:	6942                	ld	s2,16(sp)
    800023c4:	69a2                	ld	s3,8(sp)
    800023c6:	6145                	add	sp,sp,48
    800023c8:	8082                	ret
    panic("sched p->lock");
    800023ca:	00007517          	auipc	a0,0x7
    800023ce:	e2e50513          	add	a0,a0,-466 # 800091f8 <etext+0x1f8>
    800023d2:	ffffe097          	auipc	ra,0xffffe
    800023d6:	18e080e7          	jalr	398(ra) # 80000560 <panic>
    panic("sched locks");
    800023da:	00007517          	auipc	a0,0x7
    800023de:	e2e50513          	add	a0,a0,-466 # 80009208 <etext+0x208>
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	17e080e7          	jalr	382(ra) # 80000560 <panic>
    panic("sched running");
    800023ea:	00007517          	auipc	a0,0x7
    800023ee:	e2e50513          	add	a0,a0,-466 # 80009218 <etext+0x218>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	16e080e7          	jalr	366(ra) # 80000560 <panic>
    panic("sched interruptible");
    800023fa:	00007517          	auipc	a0,0x7
    800023fe:	e2e50513          	add	a0,a0,-466 # 80009228 <etext+0x228>
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	15e080e7          	jalr	350(ra) # 80000560 <panic>

000000008000240a <yield>:
{
    8000240a:	1101                	add	sp,sp,-32
    8000240c:	ec06                	sd	ra,24(sp)
    8000240e:	e822                	sd	s0,16(sp)
    80002410:	e426                	sd	s1,8(sp)
    80002412:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	776080e7          	jalr	1910(ra) # 80001b8a <myproc>
    8000241c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	81a080e7          	jalr	-2022(ra) # 80000c38 <acquire>
  p->state = RUNNABLE;
    80002426:	478d                	li	a5,3
    80002428:	cc9c                	sw	a5,24(s1)
  sched();
    8000242a:	00000097          	auipc	ra,0x0
    8000242e:	f0a080e7          	jalr	-246(ra) # 80002334 <sched>
  release(&p->lock);
    80002432:	8526                	mv	a0,s1
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	8b8080e7          	jalr	-1864(ra) # 80000cec <release>
}
    8000243c:	60e2                	ld	ra,24(sp)
    8000243e:	6442                	ld	s0,16(sp)
    80002440:	64a2                	ld	s1,8(sp)
    80002442:	6105                	add	sp,sp,32
    80002444:	8082                	ret

0000000080002446 <set_priority>:
{
    80002446:	7179                	add	sp,sp,-48
    80002448:	f406                	sd	ra,40(sp)
    8000244a:	f022                	sd	s0,32(sp)
    8000244c:	ec26                	sd	s1,24(sp)
    8000244e:	e84a                	sd	s2,16(sp)
    80002450:	e44e                	sd	s3,8(sp)
    80002452:	e052                	sd	s4,0(sp)
    80002454:	1800                	add	s0,sp,48
    80002456:	8a2a                	mv	s4,a0
    80002458:	892e                	mv	s2,a1
  for (p = proc; p < &proc[NPROC]; p++)
    8000245a:	00010497          	auipc	s1,0x10
    8000245e:	e4648493          	add	s1,s1,-442 # 800122a0 <proc>
    80002462:	00017997          	auipc	s3,0x17
    80002466:	e3e98993          	add	s3,s3,-450 # 800192a0 <tickslock>
    acquire(&p->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	ffffe097          	auipc	ra,0xffffe
    80002470:	7cc080e7          	jalr	1996(ra) # 80000c38 <acquire>
    if (p->pid == pid) // check if same pid
    80002474:	589c                	lw	a5,48(s1)
    80002476:	01278d63          	beq	a5,s2,80002490 <set_priority+0x4a>
    release(&p->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	870080e7          	jalr	-1936(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002484:	1c048493          	add	s1,s1,448
    80002488:	ff3491e3          	bne	s1,s3,8000246a <set_priority+0x24>
  return -1; // pid not found
    8000248c:	597d                	li	s2,-1
    8000248e:	a01d                	j	800024b4 <set_priority+0x6e>
      int previous_priority = p->static_priority; // for return
    80002490:	1a44a903          	lw	s2,420(s1)
      p->static_priority = new_priority;
    80002494:	1b44a223          	sw	s4,420(s1)
      p->run_time = 0;
    80002498:	1804aa23          	sw	zero,404(s1)
      p->sleep_time = 0;
    8000249c:	1804ae23          	sw	zero,412(s1)
      p->niceness = 5;
    800024a0:	4795                	li	a5,5
    800024a2:	1af4a423          	sw	a5,424(s1)
      release(&p->lock); // release lock before returning from function
    800024a6:	8526                	mv	a0,s1
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	844080e7          	jalr	-1980(ra) # 80000cec <release>
      if (previous_priority > new_priority) // check if rescheduling necessary
    800024b0:	012a4b63          	blt	s4,s2,800024c6 <set_priority+0x80>
}
    800024b4:	854a                	mv	a0,s2
    800024b6:	70a2                	ld	ra,40(sp)
    800024b8:	7402                	ld	s0,32(sp)
    800024ba:	64e2                	ld	s1,24(sp)
    800024bc:	6942                	ld	s2,16(sp)
    800024be:	69a2                	ld	s3,8(sp)
    800024c0:	6a02                	ld	s4,0(sp)
    800024c2:	6145                	add	sp,sp,48
    800024c4:	8082                	ret
        yield();
    800024c6:	00000097          	auipc	ra,0x0
    800024ca:	f44080e7          	jalr	-188(ra) # 8000240a <yield>
    800024ce:	b7dd                	j	800024b4 <set_priority+0x6e>

00000000800024d0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800024d0:	7179                	add	sp,sp,-48
    800024d2:	f406                	sd	ra,40(sp)
    800024d4:	f022                	sd	s0,32(sp)
    800024d6:	ec26                	sd	s1,24(sp)
    800024d8:	e84a                	sd	s2,16(sp)
    800024da:	e44e                	sd	s3,8(sp)
    800024dc:	1800                	add	s0,sp,48
    800024de:	89aa                	mv	s3,a0
    800024e0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024e2:	fffff097          	auipc	ra,0xfffff
    800024e6:	6a8080e7          	jalr	1704(ra) # 80001b8a <myproc>
    800024ea:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	74c080e7          	jalr	1868(ra) # 80000c38 <acquire>
  release(lk);
    800024f4:	854a                	mv	a0,s2
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	7f6080e7          	jalr	2038(ra) # 80000cec <release>

  // Go to sleep.
  p->chan = chan;
    800024fe:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002502:	4789                	li	a5,2
    80002504:	cc9c                	sw	a5,24(s1)

  sched();
    80002506:	00000097          	auipc	ra,0x0
    8000250a:	e2e080e7          	jalr	-466(ra) # 80002334 <sched>

  // Tidy up.
  p->chan = 0;
    8000250e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	7d8080e7          	jalr	2008(ra) # 80000cec <release>
  acquire(lk);
    8000251c:	854a                	mv	a0,s2
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	71a080e7          	jalr	1818(ra) # 80000c38 <acquire>
}
    80002526:	70a2                	ld	ra,40(sp)
    80002528:	7402                	ld	s0,32(sp)
    8000252a:	64e2                	ld	s1,24(sp)
    8000252c:	6942                	ld	s2,16(sp)
    8000252e:	69a2                	ld	s3,8(sp)
    80002530:	6145                	add	sp,sp,48
    80002532:	8082                	ret

0000000080002534 <waitx>:
{
    80002534:	711d                	add	sp,sp,-96
    80002536:	ec86                	sd	ra,88(sp)
    80002538:	e8a2                	sd	s0,80(sp)
    8000253a:	e4a6                	sd	s1,72(sp)
    8000253c:	e0ca                	sd	s2,64(sp)
    8000253e:	fc4e                	sd	s3,56(sp)
    80002540:	f852                	sd	s4,48(sp)
    80002542:	f456                	sd	s5,40(sp)
    80002544:	f05a                	sd	s6,32(sp)
    80002546:	ec5e                	sd	s7,24(sp)
    80002548:	e862                	sd	s8,16(sp)
    8000254a:	e466                	sd	s9,8(sp)
    8000254c:	e06a                	sd	s10,0(sp)
    8000254e:	1080                	add	s0,sp,96
    80002550:	8b2a                	mv	s6,a0
    80002552:	8bae                	mv	s7,a1
    80002554:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	634080e7          	jalr	1588(ra) # 80001b8a <myproc>
    8000255e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002560:	00010517          	auipc	a0,0x10
    80002564:	92850513          	add	a0,a0,-1752 # 80011e88 <wait_lock>
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	6d0080e7          	jalr	1744(ra) # 80000c38 <acquire>
    havekids = 0;
    80002570:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    80002572:	4a15                	li	s4,5
        havekids = 1;
    80002574:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002576:	00017997          	auipc	s3,0x17
    8000257a:	d2a98993          	add	s3,s3,-726 # 800192a0 <tickslock>
    sleep(p, &wait_lock);  
    8000257e:	00010d17          	auipc	s10,0x10
    80002582:	90ad0d13          	add	s10,s10,-1782 # 80011e88 <wait_lock>
    80002586:	a8e9                	j	80002660 <waitx+0x12c>
          pid = np->pid;
    80002588:	0304a983          	lw	s3,48(s1)
          *rtime = np->run_time;
    8000258c:	1944a783          	lw	a5,404(s1)
    80002590:	00fc2023          	sw	a5,0(s8)
          *wtime = np->exit_time - np->creation_time - np->run_time;
    80002594:	1904a703          	lw	a4,400(s1)
    80002598:	9f3d                	addw	a4,a4,a5
    8000259a:	1984a783          	lw	a5,408(s1)
    8000259e:	9f99                	subw	a5,a5,a4
    800025a0:	00fba023          	sw	a5,0(s7) # 1000 <_entry-0x7ffff000>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025a4:	000b0e63          	beqz	s6,800025c0 <waitx+0x8c>
    800025a8:	4691                	li	a3,4
    800025aa:	02c48613          	add	a2,s1,44
    800025ae:	85da                	mv	a1,s6
    800025b0:	05093503          	ld	a0,80(s2)
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	12a080e7          	jalr	298(ra) # 800016de <copyout>
    800025bc:	04054363          	bltz	a0,80002602 <waitx+0xce>
          freeproc(np);
    800025c0:	8526                	mv	a0,s1
    800025c2:	fffff097          	auipc	ra,0xfffff
    800025c6:	77a080e7          	jalr	1914(ra) # 80001d3c <freeproc>
          release(&np->lock);
    800025ca:	8526                	mv	a0,s1
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	720080e7          	jalr	1824(ra) # 80000cec <release>
          release(&wait_lock);
    800025d4:	00010517          	auipc	a0,0x10
    800025d8:	8b450513          	add	a0,a0,-1868 # 80011e88 <wait_lock>
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	710080e7          	jalr	1808(ra) # 80000cec <release>
}
    800025e4:	854e                	mv	a0,s3
    800025e6:	60e6                	ld	ra,88(sp)
    800025e8:	6446                	ld	s0,80(sp)
    800025ea:	64a6                	ld	s1,72(sp)
    800025ec:	6906                	ld	s2,64(sp)
    800025ee:	79e2                	ld	s3,56(sp)
    800025f0:	7a42                	ld	s4,48(sp)
    800025f2:	7aa2                	ld	s5,40(sp)
    800025f4:	7b02                	ld	s6,32(sp)
    800025f6:	6be2                	ld	s7,24(sp)
    800025f8:	6c42                	ld	s8,16(sp)
    800025fa:	6ca2                	ld	s9,8(sp)
    800025fc:	6d02                	ld	s10,0(sp)
    800025fe:	6125                	add	sp,sp,96
    80002600:	8082                	ret
            release(&np->lock);
    80002602:	8526                	mv	a0,s1
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	6e8080e7          	jalr	1768(ra) # 80000cec <release>
            release(&wait_lock);
    8000260c:	00010517          	auipc	a0,0x10
    80002610:	87c50513          	add	a0,a0,-1924 # 80011e88 <wait_lock>
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	6d8080e7          	jalr	1752(ra) # 80000cec <release>
            return -1;
    8000261c:	59fd                	li	s3,-1
    8000261e:	b7d9                	j	800025e4 <waitx+0xb0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002620:	1c048493          	add	s1,s1,448
    80002624:	03348463          	beq	s1,s3,8000264c <waitx+0x118>
      if(np->parent == p){
    80002628:	7c9c                	ld	a5,56(s1)
    8000262a:	ff279be3          	bne	a5,s2,80002620 <waitx+0xec>
        acquire(&np->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	608080e7          	jalr	1544(ra) # 80000c38 <acquire>
        if(np->state == ZOMBIE){
    80002638:	4c9c                	lw	a5,24(s1)
    8000263a:	f54787e3          	beq	a5,s4,80002588 <waitx+0x54>
        release(&np->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	6ac080e7          	jalr	1708(ra) # 80000cec <release>
        havekids = 1;
    80002648:	8756                	mv	a4,s5
    8000264a:	bfd9                	j	80002620 <waitx+0xec>
    if(!havekids || p->killed){
    8000264c:	c305                	beqz	a4,8000266c <waitx+0x138>
    8000264e:	02892783          	lw	a5,40(s2)
    80002652:	ef89                	bnez	a5,8000266c <waitx+0x138>
    sleep(p, &wait_lock);  
    80002654:	85ea                	mv	a1,s10
    80002656:	854a                	mv	a0,s2
    80002658:	00000097          	auipc	ra,0x0
    8000265c:	e78080e7          	jalr	-392(ra) # 800024d0 <sleep>
    havekids = 0;
    80002660:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002662:	00010497          	auipc	s1,0x10
    80002666:	c3e48493          	add	s1,s1,-962 # 800122a0 <proc>
    8000266a:	bf7d                	j	80002628 <waitx+0xf4>
      release(&wait_lock);
    8000266c:	00010517          	auipc	a0,0x10
    80002670:	81c50513          	add	a0,a0,-2020 # 80011e88 <wait_lock>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	678080e7          	jalr	1656(ra) # 80000cec <release>
      return -1;
    8000267c:	59fd                	li	s3,-1
    8000267e:	b79d                	j	800025e4 <waitx+0xb0>

0000000080002680 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002680:	7139                	add	sp,sp,-64
    80002682:	fc06                	sd	ra,56(sp)
    80002684:	f822                	sd	s0,48(sp)
    80002686:	f426                	sd	s1,40(sp)
    80002688:	f04a                	sd	s2,32(sp)
    8000268a:	ec4e                	sd	s3,24(sp)
    8000268c:	e852                	sd	s4,16(sp)
    8000268e:	e456                	sd	s5,8(sp)
    80002690:	0080                	add	s0,sp,64
    80002692:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002694:	00010497          	auipc	s1,0x10
    80002698:	c0c48493          	add	s1,s1,-1012 # 800122a0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000269c:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000269e:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800026a0:	00017917          	auipc	s2,0x17
    800026a4:	c0090913          	add	s2,s2,-1024 # 800192a0 <tickslock>
    800026a8:	a811                	j	800026bc <wakeup+0x3c>
      }
      release(&p->lock);
    800026aa:	8526                	mv	a0,s1
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	640080e7          	jalr	1600(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026b4:	1c048493          	add	s1,s1,448
    800026b8:	03248663          	beq	s1,s2,800026e4 <wakeup+0x64>
    if (p != myproc())
    800026bc:	fffff097          	auipc	ra,0xfffff
    800026c0:	4ce080e7          	jalr	1230(ra) # 80001b8a <myproc>
    800026c4:	fea488e3          	beq	s1,a0,800026b4 <wakeup+0x34>
      acquire(&p->lock);
    800026c8:	8526                	mv	a0,s1
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	56e080e7          	jalr	1390(ra) # 80000c38 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800026d2:	4c9c                	lw	a5,24(s1)
    800026d4:	fd379be3          	bne	a5,s3,800026aa <wakeup+0x2a>
    800026d8:	709c                	ld	a5,32(s1)
    800026da:	fd4798e3          	bne	a5,s4,800026aa <wakeup+0x2a>
        p->state = RUNNABLE;
    800026de:	0154ac23          	sw	s5,24(s1)
    800026e2:	b7e1                	j	800026aa <wakeup+0x2a>
    }
  }
}
    800026e4:	70e2                	ld	ra,56(sp)
    800026e6:	7442                	ld	s0,48(sp)
    800026e8:	74a2                	ld	s1,40(sp)
    800026ea:	7902                	ld	s2,32(sp)
    800026ec:	69e2                	ld	s3,24(sp)
    800026ee:	6a42                	ld	s4,16(sp)
    800026f0:	6aa2                	ld	s5,8(sp)
    800026f2:	6121                	add	sp,sp,64
    800026f4:	8082                	ret

00000000800026f6 <reparent>:
{
    800026f6:	7179                	add	sp,sp,-48
    800026f8:	f406                	sd	ra,40(sp)
    800026fa:	f022                	sd	s0,32(sp)
    800026fc:	ec26                	sd	s1,24(sp)
    800026fe:	e84a                	sd	s2,16(sp)
    80002700:	e44e                	sd	s3,8(sp)
    80002702:	e052                	sd	s4,0(sp)
    80002704:	1800                	add	s0,sp,48
    80002706:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002708:	00010497          	auipc	s1,0x10
    8000270c:	b9848493          	add	s1,s1,-1128 # 800122a0 <proc>
      pp->parent = initproc;
    80002710:	00007a17          	auipc	s4,0x7
    80002714:	4e8a0a13          	add	s4,s4,1256 # 80009bf8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002718:	00017997          	auipc	s3,0x17
    8000271c:	b8898993          	add	s3,s3,-1144 # 800192a0 <tickslock>
    80002720:	a029                	j	8000272a <reparent+0x34>
    80002722:	1c048493          	add	s1,s1,448
    80002726:	01348d63          	beq	s1,s3,80002740 <reparent+0x4a>
    if (pp->parent == p)
    8000272a:	7c9c                	ld	a5,56(s1)
    8000272c:	ff279be3          	bne	a5,s2,80002722 <reparent+0x2c>
      pp->parent = initproc;
    80002730:	000a3503          	ld	a0,0(s4)
    80002734:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002736:	00000097          	auipc	ra,0x0
    8000273a:	f4a080e7          	jalr	-182(ra) # 80002680 <wakeup>
    8000273e:	b7d5                	j	80002722 <reparent+0x2c>
}
    80002740:	70a2                	ld	ra,40(sp)
    80002742:	7402                	ld	s0,32(sp)
    80002744:	64e2                	ld	s1,24(sp)
    80002746:	6942                	ld	s2,16(sp)
    80002748:	69a2                	ld	s3,8(sp)
    8000274a:	6a02                	ld	s4,0(sp)
    8000274c:	6145                	add	sp,sp,48
    8000274e:	8082                	ret

0000000080002750 <exit>:
{
    80002750:	7179                	add	sp,sp,-48
    80002752:	f406                	sd	ra,40(sp)
    80002754:	f022                	sd	s0,32(sp)
    80002756:	ec26                	sd	s1,24(sp)
    80002758:	e84a                	sd	s2,16(sp)
    8000275a:	e44e                	sd	s3,8(sp)
    8000275c:	e052                	sd	s4,0(sp)
    8000275e:	1800                	add	s0,sp,48
    80002760:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002762:	fffff097          	auipc	ra,0xfffff
    80002766:	428080e7          	jalr	1064(ra) # 80001b8a <myproc>
    8000276a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000276c:	00007797          	auipc	a5,0x7
    80002770:	48c7b783          	ld	a5,1164(a5) # 80009bf8 <initproc>
    80002774:	0d050493          	add	s1,a0,208
    80002778:	15050913          	add	s2,a0,336
    8000277c:	02a79363          	bne	a5,a0,800027a2 <exit+0x52>
    panic("init exiting");
    80002780:	00007517          	auipc	a0,0x7
    80002784:	ac050513          	add	a0,a0,-1344 # 80009240 <etext+0x240>
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	dd8080e7          	jalr	-552(ra) # 80000560 <panic>
      fileclose(f);
    80002790:	00003097          	auipc	ra,0x3
    80002794:	8a0080e7          	jalr	-1888(ra) # 80005030 <fileclose>
      p->ofile[fd] = 0;
    80002798:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000279c:	04a1                	add	s1,s1,8
    8000279e:	01248563          	beq	s1,s2,800027a8 <exit+0x58>
    if (p->ofile[fd])
    800027a2:	6088                	ld	a0,0(s1)
    800027a4:	f575                	bnez	a0,80002790 <exit+0x40>
    800027a6:	bfdd                	j	8000279c <exit+0x4c>
  begin_op();
    800027a8:	00002097          	auipc	ra,0x2
    800027ac:	3be080e7          	jalr	958(ra) # 80004b66 <begin_op>
  iput(p->cwd);
    800027b0:	1509b503          	ld	a0,336(s3)
    800027b4:	00002097          	auipc	ra,0x2
    800027b8:	ba2080e7          	jalr	-1118(ra) # 80004356 <iput>
  end_op();
    800027bc:	00002097          	auipc	ra,0x2
    800027c0:	424080e7          	jalr	1060(ra) # 80004be0 <end_op>
  p->cwd = 0;
    800027c4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800027c8:	0000f497          	auipc	s1,0xf
    800027cc:	6c048493          	add	s1,s1,1728 # 80011e88 <wait_lock>
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	466080e7          	jalr	1126(ra) # 80000c38 <acquire>
  reparent(p);
    800027da:	854e                	mv	a0,s3
    800027dc:	00000097          	auipc	ra,0x0
    800027e0:	f1a080e7          	jalr	-230(ra) # 800026f6 <reparent>
  wakeup(p->parent);
    800027e4:	0389b503          	ld	a0,56(s3)
    800027e8:	00000097          	auipc	ra,0x0
    800027ec:	e98080e7          	jalr	-360(ra) # 80002680 <wakeup>
  acquire(&p->lock);
    800027f0:	854e                	mv	a0,s3
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	446080e7          	jalr	1094(ra) # 80000c38 <acquire>
  p->xstate = status;
    800027fa:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027fe:	4795                	li	a5,5
    80002800:	00f9ac23          	sw	a5,24(s3)
  p->exit_time = ticks;
    80002804:	00007797          	auipc	a5,0x7
    80002808:	3fc7a783          	lw	a5,1020(a5) # 80009c00 <ticks>
    8000280c:	18f9ac23          	sw	a5,408(s3)
  release(&wait_lock);
    80002810:	8526                	mv	a0,s1
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	4da080e7          	jalr	1242(ra) # 80000cec <release>
  sched();
    8000281a:	00000097          	auipc	ra,0x0
    8000281e:	b1a080e7          	jalr	-1254(ra) # 80002334 <sched>
  panic("zombie exit");
    80002822:	00007517          	auipc	a0,0x7
    80002826:	a2e50513          	add	a0,a0,-1490 # 80009250 <etext+0x250>
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	d36080e7          	jalr	-714(ra) # 80000560 <panic>

0000000080002832 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002832:	7179                	add	sp,sp,-48
    80002834:	f406                	sd	ra,40(sp)
    80002836:	f022                	sd	s0,32(sp)
    80002838:	ec26                	sd	s1,24(sp)
    8000283a:	e84a                	sd	s2,16(sp)
    8000283c:	e44e                	sd	s3,8(sp)
    8000283e:	1800                	add	s0,sp,48
    80002840:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002842:	00010497          	auipc	s1,0x10
    80002846:	a5e48493          	add	s1,s1,-1442 # 800122a0 <proc>
    8000284a:	00017997          	auipc	s3,0x17
    8000284e:	a5698993          	add	s3,s3,-1450 # 800192a0 <tickslock>
  {
    acquire(&p->lock);
    80002852:	8526                	mv	a0,s1
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	3e4080e7          	jalr	996(ra) # 80000c38 <acquire>
    if (p->pid == pid)
    8000285c:	589c                	lw	a5,48(s1)
    8000285e:	01278d63          	beq	a5,s2,80002878 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002862:	8526                	mv	a0,s1
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	488080e7          	jalr	1160(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000286c:	1c048493          	add	s1,s1,448
    80002870:	ff3491e3          	bne	s1,s3,80002852 <kill+0x20>
  }
  return -1;
    80002874:	557d                	li	a0,-1
    80002876:	a829                	j	80002890 <kill+0x5e>
      p->killed = 1;
    80002878:	4785                	li	a5,1
    8000287a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000287c:	4c98                	lw	a4,24(s1)
    8000287e:	4789                	li	a5,2
    80002880:	00f70f63          	beq	a4,a5,8000289e <kill+0x6c>
      release(&p->lock);
    80002884:	8526                	mv	a0,s1
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	466080e7          	jalr	1126(ra) # 80000cec <release>
      return 0;
    8000288e:	4501                	li	a0,0
}
    80002890:	70a2                	ld	ra,40(sp)
    80002892:	7402                	ld	s0,32(sp)
    80002894:	64e2                	ld	s1,24(sp)
    80002896:	6942                	ld	s2,16(sp)
    80002898:	69a2                	ld	s3,8(sp)
    8000289a:	6145                	add	sp,sp,48
    8000289c:	8082                	ret
        p->state = RUNNABLE;
    8000289e:	478d                	li	a5,3
    800028a0:	cc9c                	sw	a5,24(s1)
    800028a2:	b7cd                	j	80002884 <kill+0x52>

00000000800028a4 <setkilled>:

void setkilled(struct proc *p)
{
    800028a4:	1101                	add	sp,sp,-32
    800028a6:	ec06                	sd	ra,24(sp)
    800028a8:	e822                	sd	s0,16(sp)
    800028aa:	e426                	sd	s1,8(sp)
    800028ac:	1000                	add	s0,sp,32
    800028ae:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	388080e7          	jalr	904(ra) # 80000c38 <acquire>
  p->killed = 1;
    800028b8:	4785                	li	a5,1
    800028ba:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	42e080e7          	jalr	1070(ra) # 80000cec <release>
}
    800028c6:	60e2                	ld	ra,24(sp)
    800028c8:	6442                	ld	s0,16(sp)
    800028ca:	64a2                	ld	s1,8(sp)
    800028cc:	6105                	add	sp,sp,32
    800028ce:	8082                	ret

00000000800028d0 <killed>:

int killed(struct proc *p)
{
    800028d0:	1101                	add	sp,sp,-32
    800028d2:	ec06                	sd	ra,24(sp)
    800028d4:	e822                	sd	s0,16(sp)
    800028d6:	e426                	sd	s1,8(sp)
    800028d8:	e04a                	sd	s2,0(sp)
    800028da:	1000                	add	s0,sp,32
    800028dc:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	35a080e7          	jalr	858(ra) # 80000c38 <acquire>
  k = p->killed;
    800028e6:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800028ea:	8526                	mv	a0,s1
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	400080e7          	jalr	1024(ra) # 80000cec <release>
  return k;
}
    800028f4:	854a                	mv	a0,s2
    800028f6:	60e2                	ld	ra,24(sp)
    800028f8:	6442                	ld	s0,16(sp)
    800028fa:	64a2                	ld	s1,8(sp)
    800028fc:	6902                	ld	s2,0(sp)
    800028fe:	6105                	add	sp,sp,32
    80002900:	8082                	ret

0000000080002902 <wait>:
{
    80002902:	715d                	add	sp,sp,-80
    80002904:	e486                	sd	ra,72(sp)
    80002906:	e0a2                	sd	s0,64(sp)
    80002908:	fc26                	sd	s1,56(sp)
    8000290a:	f84a                	sd	s2,48(sp)
    8000290c:	f44e                	sd	s3,40(sp)
    8000290e:	f052                	sd	s4,32(sp)
    80002910:	ec56                	sd	s5,24(sp)
    80002912:	e85a                	sd	s6,16(sp)
    80002914:	e45e                	sd	s7,8(sp)
    80002916:	e062                	sd	s8,0(sp)
    80002918:	0880                	add	s0,sp,80
    8000291a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	26e080e7          	jalr	622(ra) # 80001b8a <myproc>
    80002924:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002926:	0000f517          	auipc	a0,0xf
    8000292a:	56250513          	add	a0,a0,1378 # 80011e88 <wait_lock>
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	30a080e7          	jalr	778(ra) # 80000c38 <acquire>
    havekids = 0;
    80002936:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002938:	4a15                	li	s4,5
        havekids = 1;
    8000293a:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000293c:	00017997          	auipc	s3,0x17
    80002940:	96498993          	add	s3,s3,-1692 # 800192a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002944:	0000fc17          	auipc	s8,0xf
    80002948:	544c0c13          	add	s8,s8,1348 # 80011e88 <wait_lock>
    8000294c:	a0d1                	j	80002a10 <wait+0x10e>
          pid = pp->pid;
    8000294e:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002952:	000b0e63          	beqz	s6,8000296e <wait+0x6c>
    80002956:	4691                	li	a3,4
    80002958:	02c48613          	add	a2,s1,44
    8000295c:	85da                	mv	a1,s6
    8000295e:	05093503          	ld	a0,80(s2)
    80002962:	fffff097          	auipc	ra,0xfffff
    80002966:	d7c080e7          	jalr	-644(ra) # 800016de <copyout>
    8000296a:	04054163          	bltz	a0,800029ac <wait+0xaa>
          freeproc(pp);
    8000296e:	8526                	mv	a0,s1
    80002970:	fffff097          	auipc	ra,0xfffff
    80002974:	3cc080e7          	jalr	972(ra) # 80001d3c <freeproc>
          release(&pp->lock);
    80002978:	8526                	mv	a0,s1
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	372080e7          	jalr	882(ra) # 80000cec <release>
          release(&wait_lock);
    80002982:	0000f517          	auipc	a0,0xf
    80002986:	50650513          	add	a0,a0,1286 # 80011e88 <wait_lock>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	362080e7          	jalr	866(ra) # 80000cec <release>
}
    80002992:	854e                	mv	a0,s3
    80002994:	60a6                	ld	ra,72(sp)
    80002996:	6406                	ld	s0,64(sp)
    80002998:	74e2                	ld	s1,56(sp)
    8000299a:	7942                	ld	s2,48(sp)
    8000299c:	79a2                	ld	s3,40(sp)
    8000299e:	7a02                	ld	s4,32(sp)
    800029a0:	6ae2                	ld	s5,24(sp)
    800029a2:	6b42                	ld	s6,16(sp)
    800029a4:	6ba2                	ld	s7,8(sp)
    800029a6:	6c02                	ld	s8,0(sp)
    800029a8:	6161                	add	sp,sp,80
    800029aa:	8082                	ret
            release(&pp->lock);
    800029ac:	8526                	mv	a0,s1
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	33e080e7          	jalr	830(ra) # 80000cec <release>
            release(&wait_lock);
    800029b6:	0000f517          	auipc	a0,0xf
    800029ba:	4d250513          	add	a0,a0,1234 # 80011e88 <wait_lock>
    800029be:	ffffe097          	auipc	ra,0xffffe
    800029c2:	32e080e7          	jalr	814(ra) # 80000cec <release>
            return -1;
    800029c6:	59fd                	li	s3,-1
    800029c8:	b7e9                	j	80002992 <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800029ca:	1c048493          	add	s1,s1,448
    800029ce:	03348463          	beq	s1,s3,800029f6 <wait+0xf4>
      if (pp->parent == p)
    800029d2:	7c9c                	ld	a5,56(s1)
    800029d4:	ff279be3          	bne	a5,s2,800029ca <wait+0xc8>
        acquire(&pp->lock);
    800029d8:	8526                	mv	a0,s1
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	25e080e7          	jalr	606(ra) # 80000c38 <acquire>
        if (pp->state == ZOMBIE)
    800029e2:	4c9c                	lw	a5,24(s1)
    800029e4:	f74785e3          	beq	a5,s4,8000294e <wait+0x4c>
        release(&pp->lock);
    800029e8:	8526                	mv	a0,s1
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	302080e7          	jalr	770(ra) # 80000cec <release>
        havekids = 1;
    800029f2:	8756                	mv	a4,s5
    800029f4:	bfd9                	j	800029ca <wait+0xc8>
    if (!havekids || killed(p))
    800029f6:	c31d                	beqz	a4,80002a1c <wait+0x11a>
    800029f8:	854a                	mv	a0,s2
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	ed6080e7          	jalr	-298(ra) # 800028d0 <killed>
    80002a02:	ed09                	bnez	a0,80002a1c <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a04:	85e2                	mv	a1,s8
    80002a06:	854a                	mv	a0,s2
    80002a08:	00000097          	auipc	ra,0x0
    80002a0c:	ac8080e7          	jalr	-1336(ra) # 800024d0 <sleep>
    havekids = 0;
    80002a10:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002a12:	00010497          	auipc	s1,0x10
    80002a16:	88e48493          	add	s1,s1,-1906 # 800122a0 <proc>
    80002a1a:	bf65                	j	800029d2 <wait+0xd0>
      release(&wait_lock);
    80002a1c:	0000f517          	auipc	a0,0xf
    80002a20:	46c50513          	add	a0,a0,1132 # 80011e88 <wait_lock>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	2c8080e7          	jalr	712(ra) # 80000cec <release>
      return -1;
    80002a2c:	59fd                	li	s3,-1
    80002a2e:	b795                	j	80002992 <wait+0x90>

0000000080002a30 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a30:	7179                	add	sp,sp,-48
    80002a32:	f406                	sd	ra,40(sp)
    80002a34:	f022                	sd	s0,32(sp)
    80002a36:	ec26                	sd	s1,24(sp)
    80002a38:	e84a                	sd	s2,16(sp)
    80002a3a:	e44e                	sd	s3,8(sp)
    80002a3c:	e052                	sd	s4,0(sp)
    80002a3e:	1800                	add	s0,sp,48
    80002a40:	84aa                	mv	s1,a0
    80002a42:	892e                	mv	s2,a1
    80002a44:	89b2                	mv	s3,a2
    80002a46:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	142080e7          	jalr	322(ra) # 80001b8a <myproc>
  if (user_dst)
    80002a50:	c08d                	beqz	s1,80002a72 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002a52:	86d2                	mv	a3,s4
    80002a54:	864e                	mv	a2,s3
    80002a56:	85ca                	mv	a1,s2
    80002a58:	6928                	ld	a0,80(a0)
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	c84080e7          	jalr	-892(ra) # 800016de <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a62:	70a2                	ld	ra,40(sp)
    80002a64:	7402                	ld	s0,32(sp)
    80002a66:	64e2                	ld	s1,24(sp)
    80002a68:	6942                	ld	s2,16(sp)
    80002a6a:	69a2                	ld	s3,8(sp)
    80002a6c:	6a02                	ld	s4,0(sp)
    80002a6e:	6145                	add	sp,sp,48
    80002a70:	8082                	ret
    memmove((char *)dst, src, len);
    80002a72:	000a061b          	sext.w	a2,s4
    80002a76:	85ce                	mv	a1,s3
    80002a78:	854a                	mv	a0,s2
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	316080e7          	jalr	790(ra) # 80000d90 <memmove>
    return 0;
    80002a82:	8526                	mv	a0,s1
    80002a84:	bff9                	j	80002a62 <either_copyout+0x32>

0000000080002a86 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a86:	7179                	add	sp,sp,-48
    80002a88:	f406                	sd	ra,40(sp)
    80002a8a:	f022                	sd	s0,32(sp)
    80002a8c:	ec26                	sd	s1,24(sp)
    80002a8e:	e84a                	sd	s2,16(sp)
    80002a90:	e44e                	sd	s3,8(sp)
    80002a92:	e052                	sd	s4,0(sp)
    80002a94:	1800                	add	s0,sp,48
    80002a96:	892a                	mv	s2,a0
    80002a98:	84ae                	mv	s1,a1
    80002a9a:	89b2                	mv	s3,a2
    80002a9c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	0ec080e7          	jalr	236(ra) # 80001b8a <myproc>
  if (user_src)
    80002aa6:	c08d                	beqz	s1,80002ac8 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002aa8:	86d2                	mv	a3,s4
    80002aaa:	864e                	mv	a2,s3
    80002aac:	85ca                	mv	a1,s2
    80002aae:	6928                	ld	a0,80(a0)
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	d82080e7          	jalr	-638(ra) # 80001832 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002ab8:	70a2                	ld	ra,40(sp)
    80002aba:	7402                	ld	s0,32(sp)
    80002abc:	64e2                	ld	s1,24(sp)
    80002abe:	6942                	ld	s2,16(sp)
    80002ac0:	69a2                	ld	s3,8(sp)
    80002ac2:	6a02                	ld	s4,0(sp)
    80002ac4:	6145                	add	sp,sp,48
    80002ac6:	8082                	ret
    memmove(dst, (char *)src, len);
    80002ac8:	000a061b          	sext.w	a2,s4
    80002acc:	85ce                	mv	a1,s3
    80002ace:	854a                	mv	a0,s2
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	2c0080e7          	jalr	704(ra) # 80000d90 <memmove>
    return 0;
    80002ad8:	8526                	mv	a0,s1
    80002ada:	bff9                	j	80002ab8 <either_copyin+0x32>

0000000080002adc <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002adc:	7159                	add	sp,sp,-112
    80002ade:	f486                	sd	ra,104(sp)
    80002ae0:	f0a2                	sd	s0,96(sp)
    80002ae2:	eca6                	sd	s1,88(sp)
    80002ae4:	e8ca                	sd	s2,80(sp)
    80002ae6:	e4ce                	sd	s3,72(sp)
    80002ae8:	e0d2                	sd	s4,64(sp)
    80002aea:	fc56                	sd	s5,56(sp)
    80002aec:	f85a                	sd	s6,48(sp)
    80002aee:	f45e                	sd	s7,40(sp)
    80002af0:	f062                	sd	s8,32(sp)
    80002af2:	ec66                	sd	s9,24(sp)
    80002af4:	e86a                	sd	s10,16(sp)
    80002af6:	e46e                	sd	s11,8(sp)
    80002af8:	1880                	add	s0,sp,112
  #endif
  #ifdef PBS
  printf("Using pbs");
  #endif
  #ifdef MLFQ
  printf("using mlfq");
    80002afa:	00006517          	auipc	a0,0x6
    80002afe:	77e50513          	add	a0,a0,1918 # 80009278 <etext+0x278>
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	aa8080e7          	jalr	-1368(ra) # 800005aa <printf>
  #endif

  printf("\n");
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	50650513          	add	a0,a0,1286 # 80009010 <etext+0x10>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a98080e7          	jalr	-1384(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b1a:	00010917          	auipc	s2,0x10
    80002b1e:	8de90913          	add	s2,s2,-1826 # 800123f8 <proc+0x158>
    80002b22:	00017997          	auipc	s3,0x17
    80002b26:	8d698993          	add	s3,s3,-1834 # 800193f8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b2a:	4c95                	li	s9,5
      state = states[p->state];
    else
      state = "???";
    80002b2c:	00006a17          	auipc	s4,0x6
    80002b30:	734a0a13          	add	s4,s4,1844 # 80009260 <etext+0x260>
    printf("%d %s %s %d", p->pid, state, p->name, p->creation_time);
    80002b34:	00006c17          	auipc	s8,0x6
    80002b38:	754c0c13          	add	s8,s8,1876 # 80009288 <etext+0x288>
    #ifdef PBS
    printf(" %d",dynamic_priority(p));
    #endif
    #ifdef MLFQ
    printf(" in queue?%s queue num%d", p->is_in_queue == 1 ? "yes" : "no", p->queue_num);
    80002b3c:	4b85                	li	s7,1
    80002b3e:	00006b17          	auipc	s6,0x6
    80002b42:	732b0b13          	add	s6,s6,1842 # 80009270 <etext+0x270>
    80002b46:	00006a97          	auipc	s5,0x6
    80002b4a:	752a8a93          	add	s5,s5,1874 # 80009298 <etext+0x298>
    80002b4e:	00006d97          	auipc	s11,0x6
    80002b52:	71ad8d93          	add	s11,s11,1818 # 80009268 <etext+0x268>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b56:	00007d17          	auipc	s10,0x7
    80002b5a:	dcad0d13          	add	s10,s10,-566 # 80009920 <states.0>
    80002b5e:	a891                	j	80002bb2 <procdump+0xd6>
    printf("%d %s %s %d", p->pid, state, p->name, p->creation_time);
    80002b60:	5c98                	lw	a4,56(s1)
    80002b62:	86a6                	mv	a3,s1
    80002b64:	ed84a583          	lw	a1,-296(s1)
    80002b68:	8562                	mv	a0,s8
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	a40080e7          	jalr	-1472(ra) # 800005aa <printf>
    printf(" in queue?%s queue num%d", p->is_in_queue == 1 ? "yes" : "no", p->queue_num);
    80002b72:	4cbc                	lw	a5,88(s1)
    80002b74:	85da                	mv	a1,s6
    80002b76:	05778e63          	beq	a5,s7,80002bd2 <procdump+0xf6>
    80002b7a:	4cf0                	lw	a2,92(s1)
    80002b7c:	8556                	mv	a0,s5
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	a2c080e7          	jalr	-1492(ra) # 800005aa <printf>
    printf(" run time %d, wait time %d", p->curr_run_time, p->wait_time);
    80002b86:	48f0                	lw	a2,84(s1)
    80002b88:	50ac                	lw	a1,96(s1)
    80002b8a:	00006517          	auipc	a0,0x6
    80002b8e:	72e50513          	add	a0,a0,1838 # 800092b8 <etext+0x2b8>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	a18080e7          	jalr	-1512(ra) # 800005aa <printf>
    #endif
    printf("\n");
    80002b9a:	00006517          	auipc	a0,0x6
    80002b9e:	47650513          	add	a0,a0,1142 # 80009010 <etext+0x10>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	a08080e7          	jalr	-1528(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002baa:	1c090913          	add	s2,s2,448
    80002bae:	03390463          	beq	s2,s3,80002bd6 <procdump+0xfa>
    if (p->state == UNUSED)
    80002bb2:	84ca                	mv	s1,s2
    80002bb4:	ec092783          	lw	a5,-320(s2)
    80002bb8:	dbed                	beqz	a5,80002baa <procdump+0xce>
      state = "???";
    80002bba:	8652                	mv	a2,s4
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bbc:	fafce2e3          	bltu	s9,a5,80002b60 <procdump+0x84>
    80002bc0:	02079713          	sll	a4,a5,0x20
    80002bc4:	01d75793          	srl	a5,a4,0x1d
    80002bc8:	97ea                	add	a5,a5,s10
    80002bca:	6390                	ld	a2,0(a5)
    80002bcc:	fa51                	bnez	a2,80002b60 <procdump+0x84>
      state = "???";
    80002bce:	8652                	mv	a2,s4
    80002bd0:	bf41                	j	80002b60 <procdump+0x84>
    printf(" in queue?%s queue num%d", p->is_in_queue == 1 ? "yes" : "no", p->queue_num);
    80002bd2:	85ee                	mv	a1,s11
    80002bd4:	b75d                	j	80002b7a <procdump+0x9e>
  }
  #ifdef MLFQ
  printf("queue sizes : ");
    80002bd6:	00006517          	auipc	a0,0x6
    80002bda:	70250513          	add	a0,a0,1794 # 800092d8 <etext+0x2d8>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	9cc080e7          	jalr	-1588(ra) # 800005aa <printf>
  for (int i = 0; i < 5; i++)
    80002be6:	00022497          	auipc	s1,0x22
    80002bea:	49a48493          	add	s1,s1,1178 # 80025080 <mlfq_queue+0xa00>
    80002bee:	00022997          	auipc	s3,0x22
    80002bf2:	4a698993          	add	s3,s3,1190 # 80025094 <mlfq_queue+0xa14>
    printf("%d ", mlfq_queue.proc_queue_size[i]);
    80002bf6:	00006917          	auipc	s2,0x6
    80002bfa:	6f290913          	add	s2,s2,1778 # 800092e8 <etext+0x2e8>
    80002bfe:	408c                	lw	a1,0(s1)
    80002c00:	854a                	mv	a0,s2
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	9a8080e7          	jalr	-1624(ra) # 800005aa <printf>
  for (int i = 0; i < 5; i++)
    80002c0a:	0491                	add	s1,s1,4
    80002c0c:	ff3499e3          	bne	s1,s3,80002bfe <procdump+0x122>
  printf("\n");
    80002c10:	00006517          	auipc	a0,0x6
    80002c14:	40050513          	add	a0,a0,1024 # 80009010 <etext+0x10>
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	992080e7          	jalr	-1646(ra) # 800005aa <printf>
  #endif
}
    80002c20:	70a6                	ld	ra,104(sp)
    80002c22:	7406                	ld	s0,96(sp)
    80002c24:	64e6                	ld	s1,88(sp)
    80002c26:	6946                	ld	s2,80(sp)
    80002c28:	69a6                	ld	s3,72(sp)
    80002c2a:	6a06                	ld	s4,64(sp)
    80002c2c:	7ae2                	ld	s5,56(sp)
    80002c2e:	7b42                	ld	s6,48(sp)
    80002c30:	7ba2                	ld	s7,40(sp)
    80002c32:	7c02                	ld	s8,32(sp)
    80002c34:	6ce2                	ld	s9,24(sp)
    80002c36:	6d42                	ld	s10,16(sp)
    80002c38:	6da2                	ld	s11,8(sp)
    80002c3a:	6165                	add	sp,sp,112
    80002c3c:	8082                	ret

0000000080002c3e <swtch>:
    80002c3e:	00153023          	sd	ra,0(a0)
    80002c42:	00253423          	sd	sp,8(a0)
    80002c46:	e900                	sd	s0,16(a0)
    80002c48:	ed04                	sd	s1,24(a0)
    80002c4a:	03253023          	sd	s2,32(a0)
    80002c4e:	03353423          	sd	s3,40(a0)
    80002c52:	03453823          	sd	s4,48(a0)
    80002c56:	03553c23          	sd	s5,56(a0)
    80002c5a:	05653023          	sd	s6,64(a0)
    80002c5e:	05753423          	sd	s7,72(a0)
    80002c62:	05853823          	sd	s8,80(a0)
    80002c66:	05953c23          	sd	s9,88(a0)
    80002c6a:	07a53023          	sd	s10,96(a0)
    80002c6e:	07b53423          	sd	s11,104(a0)
    80002c72:	0005b083          	ld	ra,0(a1)
    80002c76:	0085b103          	ld	sp,8(a1)
    80002c7a:	6980                	ld	s0,16(a1)
    80002c7c:	6d84                	ld	s1,24(a1)
    80002c7e:	0205b903          	ld	s2,32(a1)
    80002c82:	0285b983          	ld	s3,40(a1)
    80002c86:	0305ba03          	ld	s4,48(a1)
    80002c8a:	0385ba83          	ld	s5,56(a1)
    80002c8e:	0405bb03          	ld	s6,64(a1)
    80002c92:	0485bb83          	ld	s7,72(a1)
    80002c96:	0505bc03          	ld	s8,80(a1)
    80002c9a:	0585bc83          	ld	s9,88(a1)
    80002c9e:	0605bd03          	ld	s10,96(a1)
    80002ca2:	0685bd83          	ld	s11,104(a1)
    80002ca6:	8082                	ret

0000000080002ca8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ca8:	1141                	add	sp,sp,-16
    80002caa:	e406                	sd	ra,8(sp)
    80002cac:	e022                	sd	s0,0(sp)
    80002cae:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002cb0:	00006597          	auipc	a1,0x6
    80002cb4:	67058593          	add	a1,a1,1648 # 80009320 <etext+0x320>
    80002cb8:	00016517          	auipc	a0,0x16
    80002cbc:	5e850513          	add	a0,a0,1512 # 800192a0 <tickslock>
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	ee8080e7          	jalr	-280(ra) # 80000ba8 <initlock>
}
    80002cc8:	60a2                	ld	ra,8(sp)
    80002cca:	6402                	ld	s0,0(sp)
    80002ccc:	0141                	add	sp,sp,16
    80002cce:	8082                	ret

0000000080002cd0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cd0:	1141                	add	sp,sp,-16
    80002cd2:	e422                	sd	s0,8(sp)
    80002cd4:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cd6:	00004797          	auipc	a5,0x4
    80002cda:	a5a78793          	add	a5,a5,-1446 # 80006730 <kernelvec>
    80002cde:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ce2:	6422                	ld	s0,8(sp)
    80002ce4:	0141                	add	sp,sp,16
    80002ce6:	8082                	ret

0000000080002ce8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002ce8:	1141                	add	sp,sp,-16
    80002cea:	e406                	sd	ra,8(sp)
    80002cec:	e022                	sd	s0,0(sp)
    80002cee:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	e9a080e7          	jalr	-358(ra) # 80001b8a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cf8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cfc:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cfe:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002d02:	00005697          	auipc	a3,0x5
    80002d06:	2fe68693          	add	a3,a3,766 # 80008000 <_trampoline>
    80002d0a:	00005717          	auipc	a4,0x5
    80002d0e:	2f670713          	add	a4,a4,758 # 80008000 <_trampoline>
    80002d12:	8f15                	sub	a4,a4,a3
    80002d14:	040007b7          	lui	a5,0x4000
    80002d18:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002d1a:	07b2                	sll	a5,a5,0xc
    80002d1c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d1e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d22:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d24:	18002673          	csrr	a2,satp
    80002d28:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d2a:	6d30                	ld	a2,88(a0)
    80002d2c:	6138                	ld	a4,64(a0)
    80002d2e:	6585                	lui	a1,0x1
    80002d30:	972e                	add	a4,a4,a1
    80002d32:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d34:	6d38                	ld	a4,88(a0)
    80002d36:	00000617          	auipc	a2,0x0
    80002d3a:	14660613          	add	a2,a2,326 # 80002e7c <usertrap>
    80002d3e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d40:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d42:	8612                	mv	a2,tp
    80002d44:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d46:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d4a:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d4e:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d52:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d56:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d58:	6f18                	ld	a4,24(a4)
    80002d5a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d5e:	6928                	ld	a0,80(a0)
    80002d60:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002d62:	00005717          	auipc	a4,0x5
    80002d66:	33a70713          	add	a4,a4,826 # 8000809c <userret>
    80002d6a:	8f15                	sub	a4,a4,a3
    80002d6c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002d6e:	577d                	li	a4,-1
    80002d70:	177e                	sll	a4,a4,0x3f
    80002d72:	8d59                	or	a0,a0,a4
    80002d74:	9782                	jalr	a5
}
    80002d76:	60a2                	ld	ra,8(sp)
    80002d78:	6402                	ld	s0,0(sp)
    80002d7a:	0141                	add	sp,sp,16
    80002d7c:	8082                	ret

0000000080002d7e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d7e:	1101                	add	sp,sp,-32
    80002d80:	ec06                	sd	ra,24(sp)
    80002d82:	e822                	sd	s0,16(sp)
    80002d84:	e426                	sd	s1,8(sp)
    80002d86:	e04a                	sd	s2,0(sp)
    80002d88:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002d8a:	00016917          	auipc	s2,0x16
    80002d8e:	51690913          	add	s2,s2,1302 # 800192a0 <tickslock>
    80002d92:	854a                	mv	a0,s2
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	ea4080e7          	jalr	-348(ra) # 80000c38 <acquire>
  ticks++;
    80002d9c:	00007497          	auipc	s1,0x7
    80002da0:	e6448493          	add	s1,s1,-412 # 80009c00 <ticks>
    80002da4:	409c                	lw	a5,0(s1)
    80002da6:	2785                	addw	a5,a5,1
    80002da8:	c09c                	sw	a5,0(s1)
  timer_update();
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	34a080e7          	jalr	842(ra) # 800020f4 <timer_update>
  wakeup(&ticks);
    80002db2:	8526                	mv	a0,s1
    80002db4:	00000097          	auipc	ra,0x0
    80002db8:	8cc080e7          	jalr	-1844(ra) # 80002680 <wakeup>
  release(&tickslock);
    80002dbc:	854a                	mv	a0,s2
    80002dbe:	ffffe097          	auipc	ra,0xffffe
    80002dc2:	f2e080e7          	jalr	-210(ra) # 80000cec <release>
}
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	64a2                	ld	s1,8(sp)
    80002dcc:	6902                	ld	s2,0(sp)
    80002dce:	6105                	add	sp,sp,32
    80002dd0:	8082                	ret

0000000080002dd2 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dd2:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002dd6:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002dd8:	0a07d163          	bgez	a5,80002e7a <devintr+0xa8>
{
    80002ddc:	1101                	add	sp,sp,-32
    80002dde:	ec06                	sd	ra,24(sp)
    80002de0:	e822                	sd	s0,16(sp)
    80002de2:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002de4:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002de8:	46a5                	li	a3,9
    80002dea:	00d70c63          	beq	a4,a3,80002e02 <devintr+0x30>
  } else if(scause == 0x8000000000000001L){
    80002dee:	577d                	li	a4,-1
    80002df0:	177e                	sll	a4,a4,0x3f
    80002df2:	0705                	add	a4,a4,1
    return 0;
    80002df4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002df6:	06e78163          	beq	a5,a4,80002e58 <devintr+0x86>
  }
}
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	6105                	add	sp,sp,32
    80002e00:	8082                	ret
    80002e02:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    80002e04:	00004097          	auipc	ra,0x4
    80002e08:	a38080e7          	jalr	-1480(ra) # 8000683c <plic_claim>
    80002e0c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e0e:	47a9                	li	a5,10
    80002e10:	00f50963          	beq	a0,a5,80002e22 <devintr+0x50>
    } else if(irq == VIRTIO0_IRQ){
    80002e14:	4785                	li	a5,1
    80002e16:	00f50b63          	beq	a0,a5,80002e2c <devintr+0x5a>
    return 1;
    80002e1a:	4505                	li	a0,1
    } else if(irq){
    80002e1c:	ec89                	bnez	s1,80002e36 <devintr+0x64>
    80002e1e:	64a2                	ld	s1,8(sp)
    80002e20:	bfe9                	j	80002dfa <devintr+0x28>
      uartintr();
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	bd8080e7          	jalr	-1064(ra) # 800009fa <uartintr>
    if(irq)
    80002e2a:	a839                	j	80002e48 <devintr+0x76>
      virtio_disk_intr();
    80002e2c:	00004097          	auipc	ra,0x4
    80002e30:	f3a080e7          	jalr	-198(ra) # 80006d66 <virtio_disk_intr>
    if(irq)
    80002e34:	a811                	j	80002e48 <devintr+0x76>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e36:	85a6                	mv	a1,s1
    80002e38:	00006517          	auipc	a0,0x6
    80002e3c:	4f050513          	add	a0,a0,1264 # 80009328 <etext+0x328>
    80002e40:	ffffd097          	auipc	ra,0xffffd
    80002e44:	76a080e7          	jalr	1898(ra) # 800005aa <printf>
      plic_complete(irq);
    80002e48:	8526                	mv	a0,s1
    80002e4a:	00004097          	auipc	ra,0x4
    80002e4e:	a16080e7          	jalr	-1514(ra) # 80006860 <plic_complete>
    return 1;
    80002e52:	4505                	li	a0,1
    80002e54:	64a2                	ld	s1,8(sp)
    80002e56:	b755                	j	80002dfa <devintr+0x28>
    if(cpuid() == 0){
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	d06080e7          	jalr	-762(ra) # 80001b5e <cpuid>
    80002e60:	c901                	beqz	a0,80002e70 <devintr+0x9e>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e62:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e66:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e68:	14479073          	csrw	sip,a5
    return 2;
    80002e6c:	4509                	li	a0,2
    80002e6e:	b771                	j	80002dfa <devintr+0x28>
      clockintr();
    80002e70:	00000097          	auipc	ra,0x0
    80002e74:	f0e080e7          	jalr	-242(ra) # 80002d7e <clockintr>
    80002e78:	b7ed                	j	80002e62 <devintr+0x90>
}
    80002e7a:	8082                	ret

0000000080002e7c <usertrap>:
{
    80002e7c:	7179                	add	sp,sp,-48
    80002e7e:	f406                	sd	ra,40(sp)
    80002e80:	f022                	sd	s0,32(sp)
    80002e82:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e84:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e88:	1007f793          	and	a5,a5,256
    80002e8c:	ebc9                	bnez	a5,80002f1e <usertrap+0xa2>
    80002e8e:	ec26                	sd	s1,24(sp)
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e90:	00004797          	auipc	a5,0x4
    80002e94:	8a078793          	add	a5,a5,-1888 # 80006730 <kernelvec>
    80002e98:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	cee080e7          	jalr	-786(ra) # 80001b8a <myproc>
    80002ea4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ea6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ea8:	14102773          	csrr	a4,sepc
    80002eac:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eae:	14202773          	csrr	a4,scause
 if (r_scause() == 15){
    80002eb2:	47bd                	li	a5,15
    80002eb4:	08f70163          	beq	a4,a5,80002f36 <usertrap+0xba>
    80002eb8:	14202773          	csrr	a4,scause
  } else if(r_scause() == 8){
    80002ebc:	47a1                	li	a5,8
    80002ebe:	14f70363          	beq	a4,a5,80003004 <usertrap+0x188>
  } else if((which_dev = devintr()) != 0){
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	f10080e7          	jalr	-240(ra) # 80002dd2 <devintr>
    80002eca:	20050163          	beqz	a0,800030cc <usertrap+0x250>
    if (which_dev == 2){
    80002ece:	4789                	li	a5,2
    80002ed0:	08f51063          	bne	a0,a5,80002f50 <usertrap+0xd4>
      p->current_ticks_count++;
    80002ed4:	1804a783          	lw	a5,384(s1)
    80002ed8:	2785                	addw	a5,a5,1
    80002eda:	0007871b          	sext.w	a4,a5
    80002ede:	18f4a023          	sw	a5,384(s1)
      if (p->sigalarm_ticks > 0){ // if we are even checking for ticks
    80002ee2:	1704a783          	lw	a5,368(s1)
    80002ee6:	00f05763          	blez	a5,80002ef4 <usertrap+0x78>
        if (p->sigalarm_en == 0){ // when we aren't in a sigalarm sequence
    80002eea:	16c4a683          	lw	a3,364(s1)
    80002eee:	e299                	bnez	a3,80002ef4 <usertrap+0x78>
          if (p->current_ticks_count >= p->sigalarm_ticks){
    80002ef0:	14f75463          	bge	a4,a5,80003038 <usertrap+0x1bc>
      if (p && p->state == RUNNING)
    80002ef4:	4c98                	lw	a4,24(s1)
    80002ef6:	4791                	li	a5,4
    80002ef8:	04f71c63          	bne	a4,a5,80002f50 <usertrap+0xd4>
        p->curr_run_time++;
    80002efc:	1b84a783          	lw	a5,440(s1)
    80002f00:	2785                	addw	a5,a5,1
    80002f02:	1af4ac23          	sw	a5,440(s1)
        for (int i = 0; i < p->queue_num; i++)
    80002f06:	1b44a503          	lw	a0,436(s1)
    80002f0a:	18a05363          	blez	a0,80003090 <usertrap+0x214>
    80002f0e:	e84a                	sd	s2,16(sp)
    80002f10:	e44e                	sd	s3,8(sp)
    80002f12:	00022997          	auipc	s3,0x22
    80002f16:	16e98993          	add	s3,s3,366 # 80025080 <mlfq_queue+0xa00>
    80002f1a:	4901                	li	s2,0
    80002f1c:	aa99                	j	80003072 <usertrap+0x1f6>
    80002f1e:	ec26                	sd	s1,24(sp)
    80002f20:	e84a                	sd	s2,16(sp)
    80002f22:	e44e                	sd	s3,8(sp)
    80002f24:	e052                	sd	s4,0(sp)
    panic("usertrap: not from user mode");
    80002f26:	00006517          	auipc	a0,0x6
    80002f2a:	42250513          	add	a0,a0,1058 # 80009348 <etext+0x348>
    80002f2e:	ffffd097          	auipc	ra,0xffffd
    80002f32:	632080e7          	jalr	1586(ra) # 80000560 <panic>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f36:	143025f3          	csrr	a1,stval
    uint64 va = PGROUNDDOWN(r_stval());
    80002f3a:	77fd                	lui	a5,0xfffff
    80002f3c:	8dfd                	and	a1,a1,a5
    if (va >= MAXVA || va == 0)
    80002f3e:	fff58713          	add	a4,a1,-1 # fff <_entry-0x7ffff001>
    80002f42:	f80007b7          	lui	a5,0xf8000
    80002f46:	83e9                	srl	a5,a5,0x1a
    80002f48:	02e7f463          	bgeu	a5,a4,80002f70 <usertrap+0xf4>
      p->killed = 1;
    80002f4c:	4785                	li	a5,1
    80002f4e:	d51c                	sw	a5,40(a0)
  if(killed(p))
    80002f50:	8526                	mv	a0,s1
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	97e080e7          	jalr	-1666(ra) # 800028d0 <killed>
    80002f5a:	1a051663          	bnez	a0,80003106 <usertrap+0x28a>
  usertrapret();
    80002f5e:	00000097          	auipc	ra,0x0
    80002f62:	d8a080e7          	jalr	-630(ra) # 80002ce8 <usertrapret>
    80002f66:	64e2                	ld	s1,24(sp)
}
    80002f68:	70a2                	ld	ra,40(sp)
    80002f6a:	7402                	ld	s0,32(sp)
    80002f6c:	6145                	add	sp,sp,48
    80002f6e:	8082                	ret
    80002f70:	e84a                	sd	s2,16(sp)
      pte_t* pte = walk(p->pagetable, va, 0);
    80002f72:	4601                	li	a2,0
    80002f74:	6928                	ld	a0,80(a0)
    80002f76:	ffffe097          	auipc	ra,0xffffe
    80002f7a:	0a2080e7          	jalr	162(ra) # 80001018 <walk>
    80002f7e:	892a                	mv	s2,a0
      if (pte != 0){
    80002f80:	cd35                	beqz	a0,80002ffc <usertrap+0x180>
    80002f82:	e44e                	sd	s3,8(sp)
        uint flags = PTE_FLAGS(*pte);
    80002f84:	00052983          	lw	s3,0(a0)
        if ((flags & PTE_V) != 0){
    80002f88:	0019f793          	and	a5,s3,1
    80002f8c:	c3bd                	beqz	a5,80002ff2 <usertrap+0x176>
          if ((flags & PTE_COW) != 0){
    80002f8e:	2009f793          	and	a5,s3,512
    80002f92:	e791                	bnez	a5,80002f9e <usertrap+0x122>
            p->killed = 1;
    80002f94:	4785                	li	a5,1
    80002f96:	d49c                	sw	a5,40(s1)
    80002f98:	6942                	ld	s2,16(sp)
    80002f9a:	69a2                	ld	s3,8(sp)
    80002f9c:	bf55                	j	80002f50 <usertrap+0xd4>
            void* mem = kalloc();
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	baa080e7          	jalr	-1110(ra) # 80000b48 <kalloc>
            if (mem == 0){
    80002fa6:	c129                	beqz	a0,80002fe8 <usertrap+0x16c>
    80002fa8:	e052                	sd	s4,0(sp)
              uint64 pa = PTE2PA(*pte);
    80002faa:	00093a03          	ld	s4,0(s2)
    80002fae:	00aa5a13          	srl	s4,s4,0xa
    80002fb2:	0a32                	sll	s4,s4,0xc
              *pte = PA2PTE(mem);
    80002fb4:	00c55793          	srl	a5,a0,0xc
    80002fb8:	00a79713          	sll	a4,a5,0xa
            flags = flags & (~PTE_COW);
    80002fbc:	1ff9f793          	and	a5,s3,511
              *pte = *pte | flags;
    80002fc0:	0047e793          	or	a5,a5,4
    80002fc4:	8fd9                	or	a5,a5,a4
    80002fc6:	00f93023          	sd	a5,0(s2)
              memmove(mem, (void*)pa, PGSIZE);
    80002fca:	6605                	lui	a2,0x1
    80002fcc:	85d2                	mv	a1,s4
    80002fce:	ffffe097          	auipc	ra,0xffffe
    80002fd2:	dc2080e7          	jalr	-574(ra) # 80000d90 <memmove>
              kfree((void*)pa);
    80002fd6:	8552                	mv	a0,s4
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	a72080e7          	jalr	-1422(ra) # 80000a4a <kfree>
    80002fe0:	6942                	ld	s2,16(sp)
    80002fe2:	69a2                	ld	s3,8(sp)
    80002fe4:	6a02                	ld	s4,0(sp)
    80002fe6:	b7ad                	j	80002f50 <usertrap+0xd4>
              p->killed = 1;
    80002fe8:	4785                	li	a5,1
    80002fea:	d49c                	sw	a5,40(s1)
    80002fec:	6942                	ld	s2,16(sp)
    80002fee:	69a2                	ld	s3,8(sp)
    80002ff0:	b785                	j	80002f50 <usertrap+0xd4>
          p->killed = 1;
    80002ff2:	4785                	li	a5,1
    80002ff4:	d49c                	sw	a5,40(s1)
    80002ff6:	6942                	ld	s2,16(sp)
    80002ff8:	69a2                	ld	s3,8(sp)
    80002ffa:	bf99                	j	80002f50 <usertrap+0xd4>
        p->killed = 1;
    80002ffc:	4785                	li	a5,1
    80002ffe:	d49c                	sw	a5,40(s1)
    80003000:	6942                	ld	s2,16(sp)
    80003002:	b7b9                	j	80002f50 <usertrap+0xd4>
    if(killed(p))
    80003004:	00000097          	auipc	ra,0x0
    80003008:	8cc080e7          	jalr	-1844(ra) # 800028d0 <killed>
    8000300c:	e105                	bnez	a0,8000302c <usertrap+0x1b0>
    p->trapframe->epc += 4;
    8000300e:	6cb8                	ld	a4,88(s1)
    80003010:	6f1c                	ld	a5,24(a4)
    80003012:	0791                	add	a5,a5,4 # fffffffff8000004 <end+0xffffffff77fdaf5c>
    80003014:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003016:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000301a:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000301e:	10079073          	csrw	sstatus,a5
    syscall();
    80003022:	00000097          	auipc	ra,0x0
    80003026:	3e6080e7          	jalr	998(ra) # 80003408 <syscall>
    8000302a:	b71d                	j	80002f50 <usertrap+0xd4>
      exit(-1);
    8000302c:	557d                	li	a0,-1
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	722080e7          	jalr	1826(ra) # 80002750 <exit>
    80003036:	bfe1                	j	8000300e <usertrap+0x192>
            p->sigalarm_en = 1;
    80003038:	4785                	li	a5,1
    8000303a:	16f4a623          	sw	a5,364(s1)
            p->current_ticks_count = 0;
    8000303e:	1804a023          	sw	zero,384(s1)
            p->tm_backup = (struct trapframe*) kalloc();
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	b06080e7          	jalr	-1274(ra) # 80000b48 <kalloc>
    8000304a:	18a4b423          	sd	a0,392(s1)
            memmove(p->tm_backup, p->trapframe, sizeof(struct trapframe));
    8000304e:	12000613          	li	a2,288
    80003052:	6cac                	ld	a1,88(s1)
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	d3c080e7          	jalr	-708(ra) # 80000d90 <memmove>
            p->trapframe->epc = p->sig_handler;
    8000305c:	6cbc                	ld	a5,88(s1)
    8000305e:	1784b703          	ld	a4,376(s1)
    80003062:	ef98                	sd	a4,24(a5)
      if (p && p->state == RUNNING)
    80003064:	bd41                	j	80002ef4 <usertrap+0x78>
        for (int i = 0; i < p->queue_num; i++)
    80003066:	2905                	addw	s2,s2,1
    80003068:	1b44a503          	lw	a0,436(s1)
    8000306c:	0991                	add	s3,s3,4
    8000306e:	00a95f63          	bge	s2,a0,8000308c <usertrap+0x210>
          if (mlfq_queue.proc_queue_size[i] != 0)
    80003072:	0009a783          	lw	a5,0(s3)
    80003076:	dbe5                	beqz	a5,80003066 <usertrap+0x1ea>
            enque(p->queue_num, p);
    80003078:	85a6                	mv	a1,s1
    8000307a:	00004097          	auipc	ra,0x4
    8000307e:	dea080e7          	jalr	-534(ra) # 80006e64 <enque>
            yield();
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	388080e7          	jalr	904(ra) # 8000240a <yield>
    8000308a:	bff1                	j	80003066 <usertrap+0x1ea>
    8000308c:	6942                	ld	s2,16(sp)
    8000308e:	69a2                	ld	s3,8(sp)
        if (p->curr_run_time >= mlfq_queue.proc_queue_max_allowable_ticks[p->queue_num])
    80003090:	28450713          	add	a4,a0,644
    80003094:	070a                	sll	a4,a4,0x2
    80003096:	00021797          	auipc	a5,0x21
    8000309a:	5ea78793          	add	a5,a5,1514 # 80024680 <mlfq_queue>
    8000309e:	97ba                	add	a5,a5,a4
    800030a0:	1b84a703          	lw	a4,440(s1)
    800030a4:	43dc                	lw	a5,4(a5)
    800030a6:	eaf745e3          	blt	a4,a5,80002f50 <usertrap+0xd4>
          enque(4 < p->queue_num + 1 ? 4 : p->queue_num + 1, p);
    800030aa:	87aa                	mv	a5,a0
    800030ac:	470d                	li	a4,3
    800030ae:	00a75363          	bge	a4,a0,800030b4 <usertrap+0x238>
    800030b2:	478d                	li	a5,3
    800030b4:	85a6                	mv	a1,s1
    800030b6:	0017851b          	addw	a0,a5,1
    800030ba:	00004097          	auipc	ra,0x4
    800030be:	daa080e7          	jalr	-598(ra) # 80006e64 <enque>
          yield();
    800030c2:	fffff097          	auipc	ra,0xfffff
    800030c6:	348080e7          	jalr	840(ra) # 8000240a <yield>
    800030ca:	b559                	j	80002f50 <usertrap+0xd4>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030cc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800030d0:	5890                	lw	a2,48(s1)
    800030d2:	00006517          	auipc	a0,0x6
    800030d6:	29650513          	add	a0,a0,662 # 80009368 <etext+0x368>
    800030da:	ffffd097          	auipc	ra,0xffffd
    800030de:	4d0080e7          	jalr	1232(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030e2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030e6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030ea:	00006517          	auipc	a0,0x6
    800030ee:	2ae50513          	add	a0,a0,686 # 80009398 <etext+0x398>
    800030f2:	ffffd097          	auipc	ra,0xffffd
    800030f6:	4b8080e7          	jalr	1208(ra) # 800005aa <printf>
    setkilled(p);
    800030fa:	8526                	mv	a0,s1
    800030fc:	fffff097          	auipc	ra,0xfffff
    80003100:	7a8080e7          	jalr	1960(ra) # 800028a4 <setkilled>
    80003104:	b5b1                	j	80002f50 <usertrap+0xd4>
    exit(-1);
    80003106:	557d                	li	a0,-1
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	648080e7          	jalr	1608(ra) # 80002750 <exit>
    80003110:	b5b9                	j	80002f5e <usertrap+0xe2>

0000000080003112 <kerneltrap>:
{
    80003112:	7139                	add	sp,sp,-64
    80003114:	fc06                	sd	ra,56(sp)
    80003116:	f822                	sd	s0,48(sp)
    80003118:	f426                	sd	s1,40(sp)
    8000311a:	e456                	sd	s5,8(sp)
    8000311c:	e05a                	sd	s6,0(sp)
    8000311e:	0080                	add	s0,sp,64
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003120:	14102b73          	csrr	s6,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003124:	10002af3          	csrr	s5,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003128:	142024f3          	csrr	s1,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000312c:	100af793          	and	a5,s5,256
    80003130:	c3b1                	beqz	a5,80003174 <kerneltrap+0x62>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003132:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003136:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80003138:	eba9                	bnez	a5,8000318a <kerneltrap+0x78>
    8000313a:	e852                	sd	s4,16(sp)
  if((which_dev = devintr()) == 0){
    8000313c:	00000097          	auipc	ra,0x0
    80003140:	c96080e7          	jalr	-874(ra) # 80002dd2 <devintr>
    80003144:	8a2a                	mv	s4,a0
    80003146:	cd29                	beqz	a0,800031a0 <kerneltrap+0x8e>
    80003148:	ec4e                	sd	s3,24(sp)
      struct proc *p = myproc();
    8000314a:	fffff097          	auipc	ra,0xfffff
    8000314e:	a40080e7          	jalr	-1472(ra) # 80001b8a <myproc>
    80003152:	89aa                	mv	s3,a0
      if (p)
    80003154:	c171                	beqz	a0,80003218 <kerneltrap+0x106>
        if (p->state == RUNNING)
    80003156:	4d18                	lw	a4,24(a0)
    80003158:	4791                	li	a5,4
    8000315a:	08f70263          	beq	a4,a5,800031de <kerneltrap+0xcc>
        for (int i = 0; i < p->queue_num; i++)
    8000315e:	1b49a503          	lw	a0,436(s3)
    80003162:	0aa05863          	blez	a0,80003212 <kerneltrap+0x100>
    80003166:	f04a                	sd	s2,32(sp)
    80003168:	00022917          	auipc	s2,0x22
    8000316c:	f1890913          	add	s2,s2,-232 # 80025080 <mlfq_queue+0xa00>
    80003170:	4481                	li	s1,0
    80003172:	a051                	j	800031f6 <kerneltrap+0xe4>
    80003174:	f04a                	sd	s2,32(sp)
    80003176:	ec4e                	sd	s3,24(sp)
    80003178:	e852                	sd	s4,16(sp)
    panic("kerneltrap: not from supervisor mode");
    8000317a:	00006517          	auipc	a0,0x6
    8000317e:	23e50513          	add	a0,a0,574 # 800093b8 <etext+0x3b8>
    80003182:	ffffd097          	auipc	ra,0xffffd
    80003186:	3de080e7          	jalr	990(ra) # 80000560 <panic>
    8000318a:	f04a                	sd	s2,32(sp)
    8000318c:	ec4e                	sd	s3,24(sp)
    8000318e:	e852                	sd	s4,16(sp)
    panic("kerneltrap: interrupts enabled");
    80003190:	00006517          	auipc	a0,0x6
    80003194:	25050513          	add	a0,a0,592 # 800093e0 <etext+0x3e0>
    80003198:	ffffd097          	auipc	ra,0xffffd
    8000319c:	3c8080e7          	jalr	968(ra) # 80000560 <panic>
    800031a0:	f04a                	sd	s2,32(sp)
    800031a2:	ec4e                	sd	s3,24(sp)
    printf("scause %p\n", scause);
    800031a4:	85a6                	mv	a1,s1
    800031a6:	00006517          	auipc	a0,0x6
    800031aa:	25a50513          	add	a0,a0,602 # 80009400 <etext+0x400>
    800031ae:	ffffd097          	auipc	ra,0xffffd
    800031b2:	3fc080e7          	jalr	1020(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031b6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800031ba:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800031be:	00006517          	auipc	a0,0x6
    800031c2:	25250513          	add	a0,a0,594 # 80009410 <etext+0x410>
    800031c6:	ffffd097          	auipc	ra,0xffffd
    800031ca:	3e4080e7          	jalr	996(ra) # 800005aa <printf>
    panic("kerneltrap");
    800031ce:	00006517          	auipc	a0,0x6
    800031d2:	25a50513          	add	a0,a0,602 # 80009428 <etext+0x428>
    800031d6:	ffffd097          	auipc	ra,0xffffd
    800031da:	38a080e7          	jalr	906(ra) # 80000560 <panic>
          p->curr_run_time++;
    800031de:	1b852783          	lw	a5,440(a0)
    800031e2:	2785                	addw	a5,a5,1
    800031e4:	1af52c23          	sw	a5,440(a0)
    800031e8:	bf9d                	j	8000315e <kerneltrap+0x4c>
        for (int i = 0; i < p->queue_num; i++)
    800031ea:	2485                	addw	s1,s1,1
    800031ec:	1b49a503          	lw	a0,436(s3)
    800031f0:	0911                	add	s2,s2,4
    800031f2:	00a4df63          	bge	s1,a0,80003210 <kerneltrap+0xfe>
          if (mlfq_queue.proc_queue_size[i] != 0)
    800031f6:	00092783          	lw	a5,0(s2)
    800031fa:	dbe5                	beqz	a5,800031ea <kerneltrap+0xd8>
            enque(p->queue_num, p);
    800031fc:	85ce                	mv	a1,s3
    800031fe:	00004097          	auipc	ra,0x4
    80003202:	c66080e7          	jalr	-922(ra) # 80006e64 <enque>
            yield();
    80003206:	fffff097          	auipc	ra,0xfffff
    8000320a:	204080e7          	jalr	516(ra) # 8000240a <yield>
    8000320e:	bff1                	j	800031ea <kerneltrap+0xd8>
    80003210:	7902                	ld	s2,32(sp)
        if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && p->curr_run_time >= mlfq_queue.proc_queue_max_allowable_ticks[p->queue_num])
    80003212:	4789                	li	a5,2
    80003214:	00fa0f63          	beq	s4,a5,80003232 <kerneltrap+0x120>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003218:	141b1073          	csrw	sepc,s6
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000321c:	100a9073          	csrw	sstatus,s5
    80003220:	69e2                	ld	s3,24(sp)
    80003222:	6a42                	ld	s4,16(sp)
}
    80003224:	70e2                	ld	ra,56(sp)
    80003226:	7442                	ld	s0,48(sp)
    80003228:	74a2                	ld	s1,40(sp)
    8000322a:	6aa2                	ld	s5,8(sp)
    8000322c:	6b02                	ld	s6,0(sp)
    8000322e:	6121                	add	sp,sp,64
    80003230:	8082                	ret
        if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && p->curr_run_time >= mlfq_queue.proc_queue_max_allowable_ticks[p->queue_num])
    80003232:	fffff097          	auipc	ra,0xfffff
    80003236:	958080e7          	jalr	-1704(ra) # 80001b8a <myproc>
    8000323a:	dd79                	beqz	a0,80003218 <kerneltrap+0x106>
    8000323c:	fffff097          	auipc	ra,0xfffff
    80003240:	94e080e7          	jalr	-1714(ra) # 80001b8a <myproc>
    80003244:	4d18                	lw	a4,24(a0)
    80003246:	4791                	li	a5,4
    80003248:	fcf718e3          	bne	a4,a5,80003218 <kerneltrap+0x106>
    8000324c:	1b49a683          	lw	a3,436(s3)
    80003250:	28468713          	add	a4,a3,644
    80003254:	070a                	sll	a4,a4,0x2
    80003256:	00021797          	auipc	a5,0x21
    8000325a:	42a78793          	add	a5,a5,1066 # 80024680 <mlfq_queue>
    8000325e:	97ba                	add	a5,a5,a4
    80003260:	1b89a703          	lw	a4,440(s3)
    80003264:	43dc                	lw	a5,4(a5)
    80003266:	faf749e3          	blt	a4,a5,80003218 <kerneltrap+0x106>
          enque(4 < p->queue_num + 1 ? 4 : p->queue_num + 1, p);
    8000326a:	8536                	mv	a0,a3
    8000326c:	478d                	li	a5,3
    8000326e:	00d7d363          	bge	a5,a3,80003274 <kerneltrap+0x162>
    80003272:	450d                	li	a0,3
    80003274:	85ce                	mv	a1,s3
    80003276:	2505                	addw	a0,a0,1
    80003278:	00004097          	auipc	ra,0x4
    8000327c:	bec080e7          	jalr	-1044(ra) # 80006e64 <enque>
          yield();
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	18a080e7          	jalr	394(ra) # 8000240a <yield>
    80003288:	bf41                	j	80003218 <kerneltrap+0x106>

000000008000328a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000328a:	1101                	add	sp,sp,-32
    8000328c:	ec06                	sd	ra,24(sp)
    8000328e:	e822                	sd	s0,16(sp)
    80003290:	e426                	sd	s1,8(sp)
    80003292:	1000                	add	s0,sp,32
    80003294:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003296:	fffff097          	auipc	ra,0xfffff
    8000329a:	8f4080e7          	jalr	-1804(ra) # 80001b8a <myproc>
  switch (n)
    8000329e:	4795                	li	a5,5
    800032a0:	0497e163          	bltu	a5,s1,800032e2 <argraw+0x58>
    800032a4:	048a                	sll	s1,s1,0x2
    800032a6:	00006717          	auipc	a4,0x6
    800032aa:	6aa70713          	add	a4,a4,1706 # 80009950 <states.0+0x30>
    800032ae:	94ba                	add	s1,s1,a4
    800032b0:	409c                	lw	a5,0(s1)
    800032b2:	97ba                	add	a5,a5,a4
    800032b4:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    800032b6:	6d3c                	ld	a5,88(a0)
    800032b8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800032ba:	60e2                	ld	ra,24(sp)
    800032bc:	6442                	ld	s0,16(sp)
    800032be:	64a2                	ld	s1,8(sp)
    800032c0:	6105                	add	sp,sp,32
    800032c2:	8082                	ret
    return p->trapframe->a1;
    800032c4:	6d3c                	ld	a5,88(a0)
    800032c6:	7fa8                	ld	a0,120(a5)
    800032c8:	bfcd                	j	800032ba <argraw+0x30>
    return p->trapframe->a2;
    800032ca:	6d3c                	ld	a5,88(a0)
    800032cc:	63c8                	ld	a0,128(a5)
    800032ce:	b7f5                	j	800032ba <argraw+0x30>
    return p->trapframe->a3;
    800032d0:	6d3c                	ld	a5,88(a0)
    800032d2:	67c8                	ld	a0,136(a5)
    800032d4:	b7dd                	j	800032ba <argraw+0x30>
    return p->trapframe->a4;
    800032d6:	6d3c                	ld	a5,88(a0)
    800032d8:	6bc8                	ld	a0,144(a5)
    800032da:	b7c5                	j	800032ba <argraw+0x30>
    return p->trapframe->a5;
    800032dc:	6d3c                	ld	a5,88(a0)
    800032de:	6fc8                	ld	a0,152(a5)
    800032e0:	bfe9                	j	800032ba <argraw+0x30>
  panic("argraw");
    800032e2:	00006517          	auipc	a0,0x6
    800032e6:	15650513          	add	a0,a0,342 # 80009438 <etext+0x438>
    800032ea:	ffffd097          	auipc	ra,0xffffd
    800032ee:	276080e7          	jalr	630(ra) # 80000560 <panic>

00000000800032f2 <fetchaddr>:
{
    800032f2:	1101                	add	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	e04a                	sd	s2,0(sp)
    800032fc:	1000                	add	s0,sp,32
    800032fe:	84aa                	mv	s1,a0
    80003300:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003302:	fffff097          	auipc	ra,0xfffff
    80003306:	888080e7          	jalr	-1912(ra) # 80001b8a <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000330a:	653c                	ld	a5,72(a0)
    8000330c:	02f4f863          	bgeu	s1,a5,8000333c <fetchaddr+0x4a>
    80003310:	00848713          	add	a4,s1,8
    80003314:	02e7e663          	bltu	a5,a4,80003340 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003318:	46a1                	li	a3,8
    8000331a:	8626                	mv	a2,s1
    8000331c:	85ca                	mv	a1,s2
    8000331e:	6928                	ld	a0,80(a0)
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	512080e7          	jalr	1298(ra) # 80001832 <copyin>
    80003328:	00a03533          	snez	a0,a0
    8000332c:	40a00533          	neg	a0,a0
}
    80003330:	60e2                	ld	ra,24(sp)
    80003332:	6442                	ld	s0,16(sp)
    80003334:	64a2                	ld	s1,8(sp)
    80003336:	6902                	ld	s2,0(sp)
    80003338:	6105                	add	sp,sp,32
    8000333a:	8082                	ret
    return -1;
    8000333c:	557d                	li	a0,-1
    8000333e:	bfcd                	j	80003330 <fetchaddr+0x3e>
    80003340:	557d                	li	a0,-1
    80003342:	b7fd                	j	80003330 <fetchaddr+0x3e>

0000000080003344 <fetchstr>:
{
    80003344:	7179                	add	sp,sp,-48
    80003346:	f406                	sd	ra,40(sp)
    80003348:	f022                	sd	s0,32(sp)
    8000334a:	ec26                	sd	s1,24(sp)
    8000334c:	e84a                	sd	s2,16(sp)
    8000334e:	e44e                	sd	s3,8(sp)
    80003350:	1800                	add	s0,sp,48
    80003352:	892a                	mv	s2,a0
    80003354:	84ae                	mv	s1,a1
    80003356:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003358:	fffff097          	auipc	ra,0xfffff
    8000335c:	832080e7          	jalr	-1998(ra) # 80001b8a <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003360:	86ce                	mv	a3,s3
    80003362:	864a                	mv	a2,s2
    80003364:	85a6                	mv	a1,s1
    80003366:	6928                	ld	a0,80(a0)
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	558080e7          	jalr	1368(ra) # 800018c0 <copyinstr>
    80003370:	00054e63          	bltz	a0,8000338c <fetchstr+0x48>
  return strlen(buf);
    80003374:	8526                	mv	a0,s1
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	b32080e7          	jalr	-1230(ra) # 80000ea8 <strlen>
}
    8000337e:	70a2                	ld	ra,40(sp)
    80003380:	7402                	ld	s0,32(sp)
    80003382:	64e2                	ld	s1,24(sp)
    80003384:	6942                	ld	s2,16(sp)
    80003386:	69a2                	ld	s3,8(sp)
    80003388:	6145                	add	sp,sp,48
    8000338a:	8082                	ret
    return -1;
    8000338c:	557d                	li	a0,-1
    8000338e:	bfc5                	j	8000337e <fetchstr+0x3a>

0000000080003390 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003390:	1101                	add	sp,sp,-32
    80003392:	ec06                	sd	ra,24(sp)
    80003394:	e822                	sd	s0,16(sp)
    80003396:	e426                	sd	s1,8(sp)
    80003398:	1000                	add	s0,sp,32
    8000339a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	eee080e7          	jalr	-274(ra) # 8000328a <argraw>
    800033a4:	c088                	sw	a0,0(s1)
}
    800033a6:	60e2                	ld	ra,24(sp)
    800033a8:	6442                	ld	s0,16(sp)
    800033aa:	64a2                	ld	s1,8(sp)
    800033ac:	6105                	add	sp,sp,32
    800033ae:	8082                	ret

00000000800033b0 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    800033b0:	1101                	add	sp,sp,-32
    800033b2:	ec06                	sd	ra,24(sp)
    800033b4:	e822                	sd	s0,16(sp)
    800033b6:	e426                	sd	s1,8(sp)
    800033b8:	1000                	add	s0,sp,32
    800033ba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	ece080e7          	jalr	-306(ra) # 8000328a <argraw>
    800033c4:	e088                	sd	a0,0(s1)
}
    800033c6:	60e2                	ld	ra,24(sp)
    800033c8:	6442                	ld	s0,16(sp)
    800033ca:	64a2                	ld	s1,8(sp)
    800033cc:	6105                	add	sp,sp,32
    800033ce:	8082                	ret

00000000800033d0 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800033d0:	7179                	add	sp,sp,-48
    800033d2:	f406                	sd	ra,40(sp)
    800033d4:	f022                	sd	s0,32(sp)
    800033d6:	ec26                	sd	s1,24(sp)
    800033d8:	e84a                	sd	s2,16(sp)
    800033da:	1800                	add	s0,sp,48
    800033dc:	84ae                	mv	s1,a1
    800033de:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800033e0:	fd840593          	add	a1,s0,-40
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	fcc080e7          	jalr	-52(ra) # 800033b0 <argaddr>
  return fetchstr(addr, buf, max);
    800033ec:	864a                	mv	a2,s2
    800033ee:	85a6                	mv	a1,s1
    800033f0:	fd843503          	ld	a0,-40(s0)
    800033f4:	00000097          	auipc	ra,0x0
    800033f8:	f50080e7          	jalr	-176(ra) # 80003344 <fetchstr>
}
    800033fc:	70a2                	ld	ra,40(sp)
    800033fe:	7402                	ld	s0,32(sp)
    80003400:	64e2                	ld	s1,24(sp)
    80003402:	6942                	ld	s2,16(sp)
    80003404:	6145                	add	sp,sp,48
    80003406:	8082                	ret

0000000080003408 <syscall>:
    [SYS_waitx] "waitx",
    [SYS_set_priority] "set_priority"
};

void syscall(void)
{
    80003408:	7159                	add	sp,sp,-112
    8000340a:	f486                	sd	ra,104(sp)
    8000340c:	f0a2                	sd	s0,96(sp)
    8000340e:	eca6                	sd	s1,88(sp)
    80003410:	e8ca                	sd	s2,80(sp)
    80003412:	e4ce                	sd	s3,72(sp)
    80003414:	e0d2                	sd	s4,64(sp)
    80003416:	fc56                	sd	s5,56(sp)
    80003418:	f85a                	sd	s6,48(sp)
    8000341a:	f45e                	sd	s7,40(sp)
    8000341c:	1880                	add	s0,sp,112
  int num;
  struct proc *p = myproc();
    8000341e:	ffffe097          	auipc	ra,0xffffe
    80003422:	76c080e7          	jalr	1900(ra) # 80001b8a <myproc>
    80003426:	89aa                	mv	s3,a0

  num = p->trapframe->a7;
    80003428:	6d3c                	ld	a5,88(a0)
    8000342a:	0a87ba83          	ld	s5,168(a5)
    8000342e:	000a8b9b          	sext.w	s7,s5

  // save the registers a0 to a6 (they contain arguments for the system calls)
  int args_copy[6];
  for (int i = 0; i < 6; i++)
    80003432:	f9840b13          	add	s6,s0,-104
  num = p->trapframe->a7;
    80003436:	895a                	mv	s2,s6
  for (int i = 0; i < 6; i++)
    80003438:	4481                	li	s1,0
    8000343a:	4a19                	li	s4,6
    argint(i, &args_copy[i]);
    8000343c:	85ca                	mv	a1,s2
    8000343e:	8526                	mv	a0,s1
    80003440:	00000097          	auipc	ra,0x0
    80003444:	f50080e7          	jalr	-176(ra) # 80003390 <argint>
  for (int i = 0; i < 6; i++)
    80003448:	2485                	addw	s1,s1,1
    8000344a:	0911                	add	s2,s2,4
    8000344c:	ff4498e3          	bne	s1,s4,8000343c <syscall+0x34>

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003450:	3afd                	addw	s5,s5,-1
    80003452:	47e5                	li	a5,25
    80003454:	0357e063          	bltu	a5,s5,80003474 <syscall+0x6c>
    80003458:	003b9713          	sll	a4,s7,0x3
    8000345c:	00006797          	auipc	a5,0x6
    80003460:	50c78793          	add	a5,a5,1292 # 80009968 <syscalls>
    80003464:	97ba                	add	a5,a5,a4
    80003466:	639c                	ld	a5,0(a5)
    80003468:	c791                	beqz	a5,80003474 <syscall+0x6c>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    8000346a:	0589b483          	ld	s1,88(s3)
    8000346e:	9782                	jalr	a5
    80003470:	f8a8                	sd	a0,112(s1)
    80003472:	a015                	j	80003496 <syscall+0x8e>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80003474:	86de                	mv	a3,s7
    80003476:	15898613          	add	a2,s3,344
    8000347a:	0309a583          	lw	a1,48(s3)
    8000347e:	00006517          	auipc	a0,0x6
    80003482:	fc250513          	add	a0,a0,-62 # 80009440 <etext+0x440>
    80003486:	ffffd097          	auipc	ra,0xffffd
    8000348a:	124080e7          	jalr	292(ra) # 800005aa <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000348e:	0589b783          	ld	a5,88(s3)
    80003492:	577d                	li	a4,-1
    80003494:	fbb8                	sd	a4,112(a5)
  }

  // Check if tracing enabled for this syscall for this process
  // If enabled, print the pid,  syscall name, parameters aand return value
  if (p->trace_opt > 0 && (p->trace_opt & (1 << num)))
    80003496:	1689a783          	lw	a5,360(s3)
    8000349a:	00f05663          	blez	a5,800034a6 <syscall+0x9e>
    8000349e:	4177d7bb          	sraw	a5,a5,s7
    800034a2:	8b85                	and	a5,a5,1
    800034a4:	ef81                	bnez	a5,800034bc <syscall+0xb4>
      printf("\b)");
    }

    printf(" -> %d\n", p->trapframe->a0); // return value
  }
}
    800034a6:	70a6                	ld	ra,104(sp)
    800034a8:	7406                	ld	s0,96(sp)
    800034aa:	64e6                	ld	s1,88(sp)
    800034ac:	6946                	ld	s2,80(sp)
    800034ae:	69a6                	ld	s3,72(sp)
    800034b0:	6a06                	ld	s4,64(sp)
    800034b2:	7ae2                	ld	s5,56(sp)
    800034b4:	7b42                	ld	s6,48(sp)
    800034b6:	7ba2                	ld	s7,40(sp)
    800034b8:	6165                	add	sp,sp,112
    800034ba:	8082                	ret
    printf("%d: syscall %s ", p->pid, syscall_names[num]); // pid and syscall name
    800034bc:	00006497          	auipc	s1,0x6
    800034c0:	5cc48493          	add	s1,s1,1484 # 80009a88 <syscall_names>
    800034c4:	003b9793          	sll	a5,s7,0x3
    800034c8:	97a6                	add	a5,a5,s1
    800034ca:	6390                	ld	a2,0(a5)
    800034cc:	0309a583          	lw	a1,48(s3)
    800034d0:	00006517          	auipc	a0,0x6
    800034d4:	f9050513          	add	a0,a0,-112 # 80009460 <etext+0x460>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	0d2080e7          	jalr	210(ra) # 800005aa <printf>
    int argCount = syscall_argc[num];
    800034e0:	0b8a                	sll	s7,s7,0x2
    800034e2:	94de                	add	s1,s1,s7
    800034e4:	0d84a483          	lw	s1,216(s1)
    if (argCount)
    800034e8:	ec89                	bnez	s1,80003502 <syscall+0xfa>
    printf(" -> %d\n", p->trapframe->a0); // return value
    800034ea:	0589b783          	ld	a5,88(s3)
    800034ee:	7bac                	ld	a1,112(a5)
    800034f0:	00006517          	auipc	a0,0x6
    800034f4:	f9050513          	add	a0,a0,-112 # 80009480 <etext+0x480>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	0b2080e7          	jalr	178(ra) # 800005aa <printf>
}
    80003500:	b75d                	j	800034a6 <syscall+0x9e>
      printf("(");
    80003502:	00006517          	auipc	a0,0x6
    80003506:	f6e50513          	add	a0,a0,-146 # 80009470 <etext+0x470>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	0a0080e7          	jalr	160(ra) # 800005aa <printf>
      for (int i = 0; i < argCount; i++)
    80003512:	02905263          	blez	s1,80003536 <syscall+0x12e>
    80003516:	048a                	sll	s1,s1,0x2
    80003518:	94da                	add	s1,s1,s6
        printf("%d ", args_copy[i]);
    8000351a:	00006917          	auipc	s2,0x6
    8000351e:	dce90913          	add	s2,s2,-562 # 800092e8 <etext+0x2e8>
    80003522:	000b2583          	lw	a1,0(s6)
    80003526:	854a                	mv	a0,s2
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	082080e7          	jalr	130(ra) # 800005aa <printf>
      for (int i = 0; i < argCount; i++)
    80003530:	0b11                	add	s6,s6,4
    80003532:	fe9b18e3          	bne	s6,s1,80003522 <syscall+0x11a>
      printf("\b)");
    80003536:	00006517          	auipc	a0,0x6
    8000353a:	f4250513          	add	a0,a0,-190 # 80009478 <etext+0x478>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	06c080e7          	jalr	108(ra) # 800005aa <printf>
    80003546:	b755                	j	800034ea <syscall+0xe2>

0000000080003548 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003548:	1101                	add	sp,sp,-32
    8000354a:	ec06                	sd	ra,24(sp)
    8000354c:	e822                	sd	s0,16(sp)
    8000354e:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80003550:	fec40593          	add	a1,s0,-20
    80003554:	4501                	li	a0,0
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	e3a080e7          	jalr	-454(ra) # 80003390 <argint>
  exit(n);
    8000355e:	fec42503          	lw	a0,-20(s0)
    80003562:	fffff097          	auipc	ra,0xfffff
    80003566:	1ee080e7          	jalr	494(ra) # 80002750 <exit>
  return 0; // not reached
}
    8000356a:	4501                	li	a0,0
    8000356c:	60e2                	ld	ra,24(sp)
    8000356e:	6442                	ld	s0,16(sp)
    80003570:	6105                	add	sp,sp,32
    80003572:	8082                	ret

0000000080003574 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003574:	1141                	add	sp,sp,-16
    80003576:	e406                	sd	ra,8(sp)
    80003578:	e022                	sd	s0,0(sp)
    8000357a:	0800                	add	s0,sp,16
  return myproc()->pid;
    8000357c:	ffffe097          	auipc	ra,0xffffe
    80003580:	60e080e7          	jalr	1550(ra) # 80001b8a <myproc>
}
    80003584:	5908                	lw	a0,48(a0)
    80003586:	60a2                	ld	ra,8(sp)
    80003588:	6402                	ld	s0,0(sp)
    8000358a:	0141                	add	sp,sp,16
    8000358c:	8082                	ret

000000008000358e <sys_fork>:

uint64
sys_fork(void)
{
    8000358e:	1141                	add	sp,sp,-16
    80003590:	e406                	sd	ra,8(sp)
    80003592:	e022                	sd	s0,0(sp)
    80003594:	0800                	add	s0,sp,16
  return fork();
    80003596:	fffff097          	auipc	ra,0xfffff
    8000359a:	a14080e7          	jalr	-1516(ra) # 80001faa <fork>
}
    8000359e:	60a2                	ld	ra,8(sp)
    800035a0:	6402                	ld	s0,0(sp)
    800035a2:	0141                	add	sp,sp,16
    800035a4:	8082                	ret

00000000800035a6 <sys_wait>:

uint64
sys_wait(void)
{
    800035a6:	1101                	add	sp,sp,-32
    800035a8:	ec06                	sd	ra,24(sp)
    800035aa:	e822                	sd	s0,16(sp)
    800035ac:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800035ae:	fe840593          	add	a1,s0,-24
    800035b2:	4501                	li	a0,0
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	dfc080e7          	jalr	-516(ra) # 800033b0 <argaddr>
  return wait(p);
    800035bc:	fe843503          	ld	a0,-24(s0)
    800035c0:	fffff097          	auipc	ra,0xfffff
    800035c4:	342080e7          	jalr	834(ra) # 80002902 <wait>
}
    800035c8:	60e2                	ld	ra,24(sp)
    800035ca:	6442                	ld	s0,16(sp)
    800035cc:	6105                	add	sp,sp,32
    800035ce:	8082                	ret

00000000800035d0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035d0:	7179                	add	sp,sp,-48
    800035d2:	f406                	sd	ra,40(sp)
    800035d4:	f022                	sd	s0,32(sp)
    800035d6:	ec26                	sd	s1,24(sp)
    800035d8:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800035da:	fdc40593          	add	a1,s0,-36
    800035de:	4501                	li	a0,0
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	db0080e7          	jalr	-592(ra) # 80003390 <argint>
  addr = myproc()->sz;
    800035e8:	ffffe097          	auipc	ra,0xffffe
    800035ec:	5a2080e7          	jalr	1442(ra) # 80001b8a <myproc>
    800035f0:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800035f2:	fdc42503          	lw	a0,-36(s0)
    800035f6:	fffff097          	auipc	ra,0xfffff
    800035fa:	958080e7          	jalr	-1704(ra) # 80001f4e <growproc>
    800035fe:	00054863          	bltz	a0,8000360e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003602:	8526                	mv	a0,s1
    80003604:	70a2                	ld	ra,40(sp)
    80003606:	7402                	ld	s0,32(sp)
    80003608:	64e2                	ld	s1,24(sp)
    8000360a:	6145                	add	sp,sp,48
    8000360c:	8082                	ret
    return -1;
    8000360e:	54fd                	li	s1,-1
    80003610:	bfcd                	j	80003602 <sys_sbrk+0x32>

0000000080003612 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003612:	7139                	add	sp,sp,-64
    80003614:	fc06                	sd	ra,56(sp)
    80003616:	f822                	sd	s0,48(sp)
    80003618:	f04a                	sd	s2,32(sp)
    8000361a:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000361c:	fcc40593          	add	a1,s0,-52
    80003620:	4501                	li	a0,0
    80003622:	00000097          	auipc	ra,0x0
    80003626:	d6e080e7          	jalr	-658(ra) # 80003390 <argint>
  acquire(&tickslock);
    8000362a:	00016517          	auipc	a0,0x16
    8000362e:	c7650513          	add	a0,a0,-906 # 800192a0 <tickslock>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	606080e7          	jalr	1542(ra) # 80000c38 <acquire>
  ticks0 = ticks;
    8000363a:	00006917          	auipc	s2,0x6
    8000363e:	5c692903          	lw	s2,1478(s2) # 80009c00 <ticks>
  while (ticks - ticks0 < n)
    80003642:	fcc42783          	lw	a5,-52(s0)
    80003646:	c3b9                	beqz	a5,8000368c <sys_sleep+0x7a>
    80003648:	f426                	sd	s1,40(sp)
    8000364a:	ec4e                	sd	s3,24(sp)
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000364c:	00016997          	auipc	s3,0x16
    80003650:	c5498993          	add	s3,s3,-940 # 800192a0 <tickslock>
    80003654:	00006497          	auipc	s1,0x6
    80003658:	5ac48493          	add	s1,s1,1452 # 80009c00 <ticks>
    if (killed(myproc()))
    8000365c:	ffffe097          	auipc	ra,0xffffe
    80003660:	52e080e7          	jalr	1326(ra) # 80001b8a <myproc>
    80003664:	fffff097          	auipc	ra,0xfffff
    80003668:	26c080e7          	jalr	620(ra) # 800028d0 <killed>
    8000366c:	ed15                	bnez	a0,800036a8 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000366e:	85ce                	mv	a1,s3
    80003670:	8526                	mv	a0,s1
    80003672:	fffff097          	auipc	ra,0xfffff
    80003676:	e5e080e7          	jalr	-418(ra) # 800024d0 <sleep>
  while (ticks - ticks0 < n)
    8000367a:	409c                	lw	a5,0(s1)
    8000367c:	412787bb          	subw	a5,a5,s2
    80003680:	fcc42703          	lw	a4,-52(s0)
    80003684:	fce7ece3          	bltu	a5,a4,8000365c <sys_sleep+0x4a>
    80003688:	74a2                	ld	s1,40(sp)
    8000368a:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    8000368c:	00016517          	auipc	a0,0x16
    80003690:	c1450513          	add	a0,a0,-1004 # 800192a0 <tickslock>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	658080e7          	jalr	1624(ra) # 80000cec <release>
  return 0;
    8000369c:	4501                	li	a0,0
}
    8000369e:	70e2                	ld	ra,56(sp)
    800036a0:	7442                	ld	s0,48(sp)
    800036a2:	7902                	ld	s2,32(sp)
    800036a4:	6121                	add	sp,sp,64
    800036a6:	8082                	ret
      release(&tickslock);
    800036a8:	00016517          	auipc	a0,0x16
    800036ac:	bf850513          	add	a0,a0,-1032 # 800192a0 <tickslock>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	63c080e7          	jalr	1596(ra) # 80000cec <release>
      return -1;
    800036b8:	557d                	li	a0,-1
    800036ba:	74a2                	ld	s1,40(sp)
    800036bc:	69e2                	ld	s3,24(sp)
    800036be:	b7c5                	j	8000369e <sys_sleep+0x8c>

00000000800036c0 <sys_kill>:

uint64
sys_kill(void)
{
    800036c0:	1101                	add	sp,sp,-32
    800036c2:	ec06                	sd	ra,24(sp)
    800036c4:	e822                	sd	s0,16(sp)
    800036c6:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    800036c8:	fec40593          	add	a1,s0,-20
    800036cc:	4501                	li	a0,0
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	cc2080e7          	jalr	-830(ra) # 80003390 <argint>
  return kill(pid);
    800036d6:	fec42503          	lw	a0,-20(s0)
    800036da:	fffff097          	auipc	ra,0xfffff
    800036de:	158080e7          	jalr	344(ra) # 80002832 <kill>
}
    800036e2:	60e2                	ld	ra,24(sp)
    800036e4:	6442                	ld	s0,16(sp)
    800036e6:	6105                	add	sp,sp,32
    800036e8:	8082                	ret

00000000800036ea <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800036ea:	1101                	add	sp,sp,-32
    800036ec:	ec06                	sd	ra,24(sp)
    800036ee:	e822                	sd	s0,16(sp)
    800036f0:	e426                	sd	s1,8(sp)
    800036f2:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800036f4:	00016517          	auipc	a0,0x16
    800036f8:	bac50513          	add	a0,a0,-1108 # 800192a0 <tickslock>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	53c080e7          	jalr	1340(ra) # 80000c38 <acquire>
  xticks = ticks;
    80003704:	00006497          	auipc	s1,0x6
    80003708:	4fc4a483          	lw	s1,1276(s1) # 80009c00 <ticks>
  release(&tickslock);
    8000370c:	00016517          	auipc	a0,0x16
    80003710:	b9450513          	add	a0,a0,-1132 # 800192a0 <tickslock>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	5d8080e7          	jalr	1496(ra) # 80000cec <release>
  return xticks;
}
    8000371c:	02049513          	sll	a0,s1,0x20
    80003720:	9101                	srl	a0,a0,0x20
    80003722:	60e2                	ld	ra,24(sp)
    80003724:	6442                	ld	s0,16(sp)
    80003726:	64a2                	ld	s1,8(sp)
    80003728:	6105                	add	sp,sp,32
    8000372a:	8082                	ret

000000008000372c <sys_trace>:

// edit the processes' trace option
uint64
sys_trace(void)
{
    8000372c:	1101                	add	sp,sp,-32
    8000372e:	ec06                	sd	ra,24(sp)
    80003730:	e822                	sd	s0,16(sp)
    80003732:	1000                	add	s0,sp,32
  // fetch the trace number to be applied from a0
  int trace_num = 0;
    80003734:	fe042623          	sw	zero,-20(s0)
  argint(0, &trace_num);
    80003738:	fec40593          	add	a1,s0,-20
    8000373c:	4501                	li	a0,0
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	c52080e7          	jalr	-942(ra) # 80003390 <argint>

  if (trace_num < 0)
    80003746:	fec42783          	lw	a5,-20(s0)
  {
    // invalid, must be non negative
    return -1;
    8000374a:	557d                	li	a0,-1
  if (trace_num < 0)
    8000374c:	0007cb63          	bltz	a5,80003762 <sys_trace+0x36>
  }

  // apply the trace number as the trace option for current process
  struct proc *currProc = myproc();
    80003750:	ffffe097          	auipc	ra,0xffffe
    80003754:	43a080e7          	jalr	1082(ra) # 80001b8a <myproc>
  currProc->trace_opt = trace_num;
    80003758:	fec42783          	lw	a5,-20(s0)
    8000375c:	16f52423          	sw	a5,360(a0)

  return 0;
    80003760:	4501                	li	a0,0
}
    80003762:	60e2                	ld	ra,24(sp)
    80003764:	6442                	ld	s0,16(sp)
    80003766:	6105                	add	sp,sp,32
    80003768:	8082                	ret

000000008000376a <sys_sigalarm>:

// set an alarm to executing handler
uint64
sys_sigalarm(void)
{
    8000376a:	1101                	add	sp,sp,-32
    8000376c:	ec06                	sd	ra,24(sp)
    8000376e:	e822                	sd	s0,16(sp)
    80003770:	1000                	add	s0,sp,32
  // printf("called alarm\n");

  int sigalarm_ticks;
  uint64 sigalarm_handler;

  argaddr(1, &sigalarm_handler);
    80003772:	fe040593          	add	a1,s0,-32
    80003776:	4505                	li	a0,1
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	c38080e7          	jalr	-968(ra) # 800033b0 <argaddr>
  argint(0, &sigalarm_ticks);
    80003780:	fec40593          	add	a1,s0,-20
    80003784:	4501                	li	a0,0
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	c0a080e7          	jalr	-1014(ra) # 80003390 <argint>

  if (sigalarm_ticks == -1 || sigalarm_handler == -1)
    8000378e:	fec42703          	lw	a4,-20(s0)
    80003792:	57fd                	li	a5,-1
    80003794:	02f70b63          	beq	a4,a5,800037ca <sys_sigalarm+0x60>
    80003798:	fe043503          	ld	a0,-32(s0)
    8000379c:	02f50363          	beq	a0,a5,800037c2 <sys_sigalarm+0x58>
    return -1;

  struct proc *p = myproc();
    800037a0:	ffffe097          	auipc	ra,0xffffe
    800037a4:	3ea080e7          	jalr	1002(ra) # 80001b8a <myproc>

  p->sigalarm_ticks = sigalarm_ticks;
    800037a8:	fec42783          	lw	a5,-20(s0)
    800037ac:	16f52823          	sw	a5,368(a0)
  p->sig_handler = sigalarm_handler;
    800037b0:	fe043783          	ld	a5,-32(s0)
    800037b4:	16f53c23          	sd	a5,376(a0)
  p->sigalarm_en = 0;
    800037b8:	16052623          	sw	zero,364(a0)
  p->current_ticks_count = 0;
    800037bc:	18052023          	sw	zero,384(a0)

  return 0;
    800037c0:	4501                	li	a0,0
}
    800037c2:	60e2                	ld	ra,24(sp)
    800037c4:	6442                	ld	s0,16(sp)
    800037c6:	6105                	add	sp,sp,32
    800037c8:	8082                	ret
    return -1;
    800037ca:	557d                	li	a0,-1
    800037cc:	bfdd                	j	800037c2 <sys_sigalarm+0x58>

00000000800037ce <sys_sigreturn>:

// reset process state
uint64
sys_sigreturn(void)
{
    800037ce:	1101                	add	sp,sp,-32
    800037d0:	ec06                	sd	ra,24(sp)
    800037d2:	e822                	sd	s0,16(sp)
    800037d4:	e426                	sd	s1,8(sp)
    800037d6:	1000                	add	s0,sp,32

  // printf("called return\n");

  struct proc *p = myproc();
    800037d8:	ffffe097          	auipc	ra,0xffffe
    800037dc:	3b2080e7          	jalr	946(ra) # 80001b8a <myproc>
    800037e0:	84aa                	mv	s1,a0

  // backup restoration for test1 and test2
  memmove(p->trapframe, p->tm_backup, sizeof(struct trapframe));
    800037e2:	12000613          	li	a2,288
    800037e6:	18853583          	ld	a1,392(a0)
    800037ea:	6d28                	ld	a0,88(a0)
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	5a4080e7          	jalr	1444(ra) # 80000d90 <memmove>
  if (p->tm_backup)
    800037f4:	1884b503          	ld	a0,392(s1)
    800037f8:	c509                	beqz	a0,80003802 <sys_sigreturn+0x34>
    kfree(p->tm_backup);
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	250080e7          	jalr	592(ra) # 80000a4a <kfree>
  p->tm_backup = 0;
    80003802:	1804b423          	sd	zero,392(s1)

  p->sigalarm_en = 0;
    80003806:	1604a623          	sw	zero,364(s1)

  return p->trapframe->a0; // to restore a0
    8000380a:	6cbc                	ld	a5,88(s1)
}
    8000380c:	7ba8                	ld	a0,112(a5)
    8000380e:	60e2                	ld	ra,24(sp)
    80003810:	6442                	ld	s0,16(sp)
    80003812:	64a2                	ld	s1,8(sp)
    80003814:	6105                	add	sp,sp,32
    80003816:	8082                	ret

0000000080003818 <sys_waitx>:


uint64
sys_waitx(void)
{
    80003818:	7139                	add	sp,sp,-64
    8000381a:	fc06                	sd	ra,56(sp)
    8000381c:	f822                	sd	s0,48(sp)
    8000381e:	f426                	sd	s1,40(sp)
    80003820:	f04a                	sd	s2,32(sp)
    80003822:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003824:	fd840593          	add	a1,s0,-40
    80003828:	4501                	li	a0,0
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	b86080e7          	jalr	-1146(ra) # 800033b0 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003832:	fd040593          	add	a1,s0,-48
    80003836:	4505                	li	a0,1
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	b78080e7          	jalr	-1160(ra) # 800033b0 <argaddr>
  argaddr(2, &addr2);
    80003840:	fc840593          	add	a1,s0,-56
    80003844:	4509                	li	a0,2
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	b6a080e7          	jalr	-1174(ra) # 800033b0 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000384e:	fc040613          	add	a2,s0,-64
    80003852:	fc440593          	add	a1,s0,-60
    80003856:	fd843503          	ld	a0,-40(s0)
    8000385a:	fffff097          	auipc	ra,0xfffff
    8000385e:	cda080e7          	jalr	-806(ra) # 80002534 <waitx>
    80003862:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80003864:	ffffe097          	auipc	ra,0xffffe
    80003868:	326080e7          	jalr	806(ra) # 80001b8a <myproc>
    8000386c:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    8000386e:	4691                	li	a3,4
    80003870:	fc440613          	add	a2,s0,-60
    80003874:	fd043583          	ld	a1,-48(s0)
    80003878:	6928                	ld	a0,80(a0)
    8000387a:	ffffe097          	auipc	ra,0xffffe
    8000387e:	e64080e7          	jalr	-412(ra) # 800016de <copyout>
    return -1;
    80003882:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003884:	00054f63          	bltz	a0,800038a2 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003888:	4691                	li	a3,4
    8000388a:	fc040613          	add	a2,s0,-64
    8000388e:	fc843583          	ld	a1,-56(s0)
    80003892:	68a8                	ld	a0,80(s1)
    80003894:	ffffe097          	auipc	ra,0xffffe
    80003898:	e4a080e7          	jalr	-438(ra) # 800016de <copyout>
    8000389c:	00054a63          	bltz	a0,800038b0 <sys_waitx+0x98>
    return -1;
  return ret;
    800038a0:	87ca                	mv	a5,s2
}
    800038a2:	853e                	mv	a0,a5
    800038a4:	70e2                	ld	ra,56(sp)
    800038a6:	7442                	ld	s0,48(sp)
    800038a8:	74a2                	ld	s1,40(sp)
    800038aa:	7902                	ld	s2,32(sp)
    800038ac:	6121                	add	sp,sp,64
    800038ae:	8082                	ret
    return -1;
    800038b0:	57fd                	li	a5,-1
    800038b2:	bfc5                	j	800038a2 <sys_waitx+0x8a>

00000000800038b4 <sys_set_priority>:

// Change the static priority of the current process
uint64
sys_set_priority(void)
{
    800038b4:	1141                	add	sp,sp,-16
    800038b6:	e406                	sd	ra,8(sp)
    800038b8:	e022                	sd	s0,0(sp)
    800038ba:	0800                	add	s0,sp,16
  }

  return set_priority(new_priority, pid); 
  #endif

  printf("Error, priority based scheduler must be chosen to use this command.\n");
    800038bc:	00006517          	auipc	a0,0x6
    800038c0:	c8c50513          	add	a0,a0,-884 # 80009548 <etext+0x548>
    800038c4:	ffffd097          	auipc	ra,0xffffd
    800038c8:	ce6080e7          	jalr	-794(ra) # 800005aa <printf>
  return -1;
    800038cc:	557d                	li	a0,-1
    800038ce:	60a2                	ld	ra,8(sp)
    800038d0:	6402                	ld	s0,0(sp)
    800038d2:	0141                	add	sp,sp,16
    800038d4:	8082                	ret

00000000800038d6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800038d6:	7179                	add	sp,sp,-48
    800038d8:	f406                	sd	ra,40(sp)
    800038da:	f022                	sd	s0,32(sp)
    800038dc:	ec26                	sd	s1,24(sp)
    800038de:	e84a                	sd	s2,16(sp)
    800038e0:	e44e                	sd	s3,8(sp)
    800038e2:	e052                	sd	s4,0(sp)
    800038e4:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800038e6:	00006597          	auipc	a1,0x6
    800038ea:	caa58593          	add	a1,a1,-854 # 80009590 <etext+0x590>
    800038ee:	00016517          	auipc	a0,0x16
    800038f2:	9ca50513          	add	a0,a0,-1590 # 800192b8 <bcache>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	2b2080e7          	jalr	690(ra) # 80000ba8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800038fe:	0001e797          	auipc	a5,0x1e
    80003902:	9ba78793          	add	a5,a5,-1606 # 800212b8 <bcache+0x8000>
    80003906:	0001e717          	auipc	a4,0x1e
    8000390a:	c1a70713          	add	a4,a4,-998 # 80021520 <bcache+0x8268>
    8000390e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003912:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003916:	00016497          	auipc	s1,0x16
    8000391a:	9ba48493          	add	s1,s1,-1606 # 800192d0 <bcache+0x18>
    b->next = bcache.head.next;
    8000391e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003920:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003922:	00006a17          	auipc	s4,0x6
    80003926:	c76a0a13          	add	s4,s4,-906 # 80009598 <etext+0x598>
    b->next = bcache.head.next;
    8000392a:	2b893783          	ld	a5,696(s2)
    8000392e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003930:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003934:	85d2                	mv	a1,s4
    80003936:	01048513          	add	a0,s1,16
    8000393a:	00001097          	auipc	ra,0x1
    8000393e:	4e8080e7          	jalr	1256(ra) # 80004e22 <initsleeplock>
    bcache.head.next->prev = b;
    80003942:	2b893783          	ld	a5,696(s2)
    80003946:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003948:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000394c:	45848493          	add	s1,s1,1112
    80003950:	fd349de3          	bne	s1,s3,8000392a <binit+0x54>
  }
}
    80003954:	70a2                	ld	ra,40(sp)
    80003956:	7402                	ld	s0,32(sp)
    80003958:	64e2                	ld	s1,24(sp)
    8000395a:	6942                	ld	s2,16(sp)
    8000395c:	69a2                	ld	s3,8(sp)
    8000395e:	6a02                	ld	s4,0(sp)
    80003960:	6145                	add	sp,sp,48
    80003962:	8082                	ret

0000000080003964 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003964:	7179                	add	sp,sp,-48
    80003966:	f406                	sd	ra,40(sp)
    80003968:	f022                	sd	s0,32(sp)
    8000396a:	ec26                	sd	s1,24(sp)
    8000396c:	e84a                	sd	s2,16(sp)
    8000396e:	e44e                	sd	s3,8(sp)
    80003970:	1800                	add	s0,sp,48
    80003972:	892a                	mv	s2,a0
    80003974:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003976:	00016517          	auipc	a0,0x16
    8000397a:	94250513          	add	a0,a0,-1726 # 800192b8 <bcache>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	2ba080e7          	jalr	698(ra) # 80000c38 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003986:	0001e497          	auipc	s1,0x1e
    8000398a:	bea4b483          	ld	s1,-1046(s1) # 80021570 <bcache+0x82b8>
    8000398e:	0001e797          	auipc	a5,0x1e
    80003992:	b9278793          	add	a5,a5,-1134 # 80021520 <bcache+0x8268>
    80003996:	02f48f63          	beq	s1,a5,800039d4 <bread+0x70>
    8000399a:	873e                	mv	a4,a5
    8000399c:	a021                	j	800039a4 <bread+0x40>
    8000399e:	68a4                	ld	s1,80(s1)
    800039a0:	02e48a63          	beq	s1,a4,800039d4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800039a4:	449c                	lw	a5,8(s1)
    800039a6:	ff279ce3          	bne	a5,s2,8000399e <bread+0x3a>
    800039aa:	44dc                	lw	a5,12(s1)
    800039ac:	ff3799e3          	bne	a5,s3,8000399e <bread+0x3a>
      b->refcnt++;
    800039b0:	40bc                	lw	a5,64(s1)
    800039b2:	2785                	addw	a5,a5,1
    800039b4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800039b6:	00016517          	auipc	a0,0x16
    800039ba:	90250513          	add	a0,a0,-1790 # 800192b8 <bcache>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	32e080e7          	jalr	814(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    800039c6:	01048513          	add	a0,s1,16
    800039ca:	00001097          	auipc	ra,0x1
    800039ce:	492080e7          	jalr	1170(ra) # 80004e5c <acquiresleep>
      return b;
    800039d2:	a8b9                	j	80003a30 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800039d4:	0001e497          	auipc	s1,0x1e
    800039d8:	b944b483          	ld	s1,-1132(s1) # 80021568 <bcache+0x82b0>
    800039dc:	0001e797          	auipc	a5,0x1e
    800039e0:	b4478793          	add	a5,a5,-1212 # 80021520 <bcache+0x8268>
    800039e4:	00f48863          	beq	s1,a5,800039f4 <bread+0x90>
    800039e8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800039ea:	40bc                	lw	a5,64(s1)
    800039ec:	cf81                	beqz	a5,80003a04 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800039ee:	64a4                	ld	s1,72(s1)
    800039f0:	fee49de3          	bne	s1,a4,800039ea <bread+0x86>
  panic("bget: no buffers");
    800039f4:	00006517          	auipc	a0,0x6
    800039f8:	bac50513          	add	a0,a0,-1108 # 800095a0 <etext+0x5a0>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	b64080e7          	jalr	-1180(ra) # 80000560 <panic>
      b->dev = dev;
    80003a04:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003a08:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003a0c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003a10:	4785                	li	a5,1
    80003a12:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a14:	00016517          	auipc	a0,0x16
    80003a18:	8a450513          	add	a0,a0,-1884 # 800192b8 <bcache>
    80003a1c:	ffffd097          	auipc	ra,0xffffd
    80003a20:	2d0080e7          	jalr	720(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    80003a24:	01048513          	add	a0,s1,16
    80003a28:	00001097          	auipc	ra,0x1
    80003a2c:	434080e7          	jalr	1076(ra) # 80004e5c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003a30:	409c                	lw	a5,0(s1)
    80003a32:	cb89                	beqz	a5,80003a44 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003a34:	8526                	mv	a0,s1
    80003a36:	70a2                	ld	ra,40(sp)
    80003a38:	7402                	ld	s0,32(sp)
    80003a3a:	64e2                	ld	s1,24(sp)
    80003a3c:	6942                	ld	s2,16(sp)
    80003a3e:	69a2                	ld	s3,8(sp)
    80003a40:	6145                	add	sp,sp,48
    80003a42:	8082                	ret
    virtio_disk_rw(b, 0);
    80003a44:	4581                	li	a1,0
    80003a46:	8526                	mv	a0,s1
    80003a48:	00003097          	auipc	ra,0x3
    80003a4c:	0f0080e7          	jalr	240(ra) # 80006b38 <virtio_disk_rw>
    b->valid = 1;
    80003a50:	4785                	li	a5,1
    80003a52:	c09c                	sw	a5,0(s1)
  return b;
    80003a54:	b7c5                	j	80003a34 <bread+0xd0>

0000000080003a56 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003a56:	1101                	add	sp,sp,-32
    80003a58:	ec06                	sd	ra,24(sp)
    80003a5a:	e822                	sd	s0,16(sp)
    80003a5c:	e426                	sd	s1,8(sp)
    80003a5e:	1000                	add	s0,sp,32
    80003a60:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a62:	0541                	add	a0,a0,16
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	492080e7          	jalr	1170(ra) # 80004ef6 <holdingsleep>
    80003a6c:	cd01                	beqz	a0,80003a84 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003a6e:	4585                	li	a1,1
    80003a70:	8526                	mv	a0,s1
    80003a72:	00003097          	auipc	ra,0x3
    80003a76:	0c6080e7          	jalr	198(ra) # 80006b38 <virtio_disk_rw>
}
    80003a7a:	60e2                	ld	ra,24(sp)
    80003a7c:	6442                	ld	s0,16(sp)
    80003a7e:	64a2                	ld	s1,8(sp)
    80003a80:	6105                	add	sp,sp,32
    80003a82:	8082                	ret
    panic("bwrite");
    80003a84:	00006517          	auipc	a0,0x6
    80003a88:	b3450513          	add	a0,a0,-1228 # 800095b8 <etext+0x5b8>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	ad4080e7          	jalr	-1324(ra) # 80000560 <panic>

0000000080003a94 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003a94:	1101                	add	sp,sp,-32
    80003a96:	ec06                	sd	ra,24(sp)
    80003a98:	e822                	sd	s0,16(sp)
    80003a9a:	e426                	sd	s1,8(sp)
    80003a9c:	e04a                	sd	s2,0(sp)
    80003a9e:	1000                	add	s0,sp,32
    80003aa0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003aa2:	01050913          	add	s2,a0,16
    80003aa6:	854a                	mv	a0,s2
    80003aa8:	00001097          	auipc	ra,0x1
    80003aac:	44e080e7          	jalr	1102(ra) # 80004ef6 <holdingsleep>
    80003ab0:	c925                	beqz	a0,80003b20 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003ab2:	854a                	mv	a0,s2
    80003ab4:	00001097          	auipc	ra,0x1
    80003ab8:	3fe080e7          	jalr	1022(ra) # 80004eb2 <releasesleep>

  acquire(&bcache.lock);
    80003abc:	00015517          	auipc	a0,0x15
    80003ac0:	7fc50513          	add	a0,a0,2044 # 800192b8 <bcache>
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	174080e7          	jalr	372(ra) # 80000c38 <acquire>
  b->refcnt--;
    80003acc:	40bc                	lw	a5,64(s1)
    80003ace:	37fd                	addw	a5,a5,-1
    80003ad0:	0007871b          	sext.w	a4,a5
    80003ad4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003ad6:	e71d                	bnez	a4,80003b04 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003ad8:	68b8                	ld	a4,80(s1)
    80003ada:	64bc                	ld	a5,72(s1)
    80003adc:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003ade:	68b8                	ld	a4,80(s1)
    80003ae0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003ae2:	0001d797          	auipc	a5,0x1d
    80003ae6:	7d678793          	add	a5,a5,2006 # 800212b8 <bcache+0x8000>
    80003aea:	2b87b703          	ld	a4,696(a5)
    80003aee:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003af0:	0001e717          	auipc	a4,0x1e
    80003af4:	a3070713          	add	a4,a4,-1488 # 80021520 <bcache+0x8268>
    80003af8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003afa:	2b87b703          	ld	a4,696(a5)
    80003afe:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003b00:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003b04:	00015517          	auipc	a0,0x15
    80003b08:	7b450513          	add	a0,a0,1972 # 800192b8 <bcache>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	1e0080e7          	jalr	480(ra) # 80000cec <release>
}
    80003b14:	60e2                	ld	ra,24(sp)
    80003b16:	6442                	ld	s0,16(sp)
    80003b18:	64a2                	ld	s1,8(sp)
    80003b1a:	6902                	ld	s2,0(sp)
    80003b1c:	6105                	add	sp,sp,32
    80003b1e:	8082                	ret
    panic("brelse");
    80003b20:	00006517          	auipc	a0,0x6
    80003b24:	aa050513          	add	a0,a0,-1376 # 800095c0 <etext+0x5c0>
    80003b28:	ffffd097          	auipc	ra,0xffffd
    80003b2c:	a38080e7          	jalr	-1480(ra) # 80000560 <panic>

0000000080003b30 <bpin>:

void
bpin(struct buf *b) {
    80003b30:	1101                	add	sp,sp,-32
    80003b32:	ec06                	sd	ra,24(sp)
    80003b34:	e822                	sd	s0,16(sp)
    80003b36:	e426                	sd	s1,8(sp)
    80003b38:	1000                	add	s0,sp,32
    80003b3a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b3c:	00015517          	auipc	a0,0x15
    80003b40:	77c50513          	add	a0,a0,1916 # 800192b8 <bcache>
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	0f4080e7          	jalr	244(ra) # 80000c38 <acquire>
  b->refcnt++;
    80003b4c:	40bc                	lw	a5,64(s1)
    80003b4e:	2785                	addw	a5,a5,1
    80003b50:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b52:	00015517          	auipc	a0,0x15
    80003b56:	76650513          	add	a0,a0,1894 # 800192b8 <bcache>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	192080e7          	jalr	402(ra) # 80000cec <release>
}
    80003b62:	60e2                	ld	ra,24(sp)
    80003b64:	6442                	ld	s0,16(sp)
    80003b66:	64a2                	ld	s1,8(sp)
    80003b68:	6105                	add	sp,sp,32
    80003b6a:	8082                	ret

0000000080003b6c <bunpin>:

void
bunpin(struct buf *b) {
    80003b6c:	1101                	add	sp,sp,-32
    80003b6e:	ec06                	sd	ra,24(sp)
    80003b70:	e822                	sd	s0,16(sp)
    80003b72:	e426                	sd	s1,8(sp)
    80003b74:	1000                	add	s0,sp,32
    80003b76:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b78:	00015517          	auipc	a0,0x15
    80003b7c:	74050513          	add	a0,a0,1856 # 800192b8 <bcache>
    80003b80:	ffffd097          	auipc	ra,0xffffd
    80003b84:	0b8080e7          	jalr	184(ra) # 80000c38 <acquire>
  b->refcnt--;
    80003b88:	40bc                	lw	a5,64(s1)
    80003b8a:	37fd                	addw	a5,a5,-1
    80003b8c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b8e:	00015517          	auipc	a0,0x15
    80003b92:	72a50513          	add	a0,a0,1834 # 800192b8 <bcache>
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	156080e7          	jalr	342(ra) # 80000cec <release>
}
    80003b9e:	60e2                	ld	ra,24(sp)
    80003ba0:	6442                	ld	s0,16(sp)
    80003ba2:	64a2                	ld	s1,8(sp)
    80003ba4:	6105                	add	sp,sp,32
    80003ba6:	8082                	ret

0000000080003ba8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003ba8:	1101                	add	sp,sp,-32
    80003baa:	ec06                	sd	ra,24(sp)
    80003bac:	e822                	sd	s0,16(sp)
    80003bae:	e426                	sd	s1,8(sp)
    80003bb0:	e04a                	sd	s2,0(sp)
    80003bb2:	1000                	add	s0,sp,32
    80003bb4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003bb6:	00d5d59b          	srlw	a1,a1,0xd
    80003bba:	0001e797          	auipc	a5,0x1e
    80003bbe:	dda7a783          	lw	a5,-550(a5) # 80021994 <sb+0x1c>
    80003bc2:	9dbd                	addw	a1,a1,a5
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	da0080e7          	jalr	-608(ra) # 80003964 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003bcc:	0074f713          	and	a4,s1,7
    80003bd0:	4785                	li	a5,1
    80003bd2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003bd6:	14ce                	sll	s1,s1,0x33
    80003bd8:	90d9                	srl	s1,s1,0x36
    80003bda:	00950733          	add	a4,a0,s1
    80003bde:	05874703          	lbu	a4,88(a4)
    80003be2:	00e7f6b3          	and	a3,a5,a4
    80003be6:	c69d                	beqz	a3,80003c14 <bfree+0x6c>
    80003be8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003bea:	94aa                	add	s1,s1,a0
    80003bec:	fff7c793          	not	a5,a5
    80003bf0:	8f7d                	and	a4,a4,a5
    80003bf2:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	148080e7          	jalr	328(ra) # 80004d3e <log_write>
  brelse(bp);
    80003bfe:	854a                	mv	a0,s2
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	e94080e7          	jalr	-364(ra) # 80003a94 <brelse>
}
    80003c08:	60e2                	ld	ra,24(sp)
    80003c0a:	6442                	ld	s0,16(sp)
    80003c0c:	64a2                	ld	s1,8(sp)
    80003c0e:	6902                	ld	s2,0(sp)
    80003c10:	6105                	add	sp,sp,32
    80003c12:	8082                	ret
    panic("freeing free block");
    80003c14:	00006517          	auipc	a0,0x6
    80003c18:	9b450513          	add	a0,a0,-1612 # 800095c8 <etext+0x5c8>
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	944080e7          	jalr	-1724(ra) # 80000560 <panic>

0000000080003c24 <balloc>:
{
    80003c24:	711d                	add	sp,sp,-96
    80003c26:	ec86                	sd	ra,88(sp)
    80003c28:	e8a2                	sd	s0,80(sp)
    80003c2a:	e4a6                	sd	s1,72(sp)
    80003c2c:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003c2e:	0001e797          	auipc	a5,0x1e
    80003c32:	d4e7a783          	lw	a5,-690(a5) # 8002197c <sb+0x4>
    80003c36:	10078f63          	beqz	a5,80003d54 <balloc+0x130>
    80003c3a:	e0ca                	sd	s2,64(sp)
    80003c3c:	fc4e                	sd	s3,56(sp)
    80003c3e:	f852                	sd	s4,48(sp)
    80003c40:	f456                	sd	s5,40(sp)
    80003c42:	f05a                	sd	s6,32(sp)
    80003c44:	ec5e                	sd	s7,24(sp)
    80003c46:	e862                	sd	s8,16(sp)
    80003c48:	e466                	sd	s9,8(sp)
    80003c4a:	8baa                	mv	s7,a0
    80003c4c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003c4e:	0001eb17          	auipc	s6,0x1e
    80003c52:	d2ab0b13          	add	s6,s6,-726 # 80021978 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c56:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003c58:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c5a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003c5c:	6c89                	lui	s9,0x2
    80003c5e:	a061                	j	80003ce6 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003c60:	97ca                	add	a5,a5,s2
    80003c62:	8e55                	or	a2,a2,a3
    80003c64:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003c68:	854a                	mv	a0,s2
    80003c6a:	00001097          	auipc	ra,0x1
    80003c6e:	0d4080e7          	jalr	212(ra) # 80004d3e <log_write>
        brelse(bp);
    80003c72:	854a                	mv	a0,s2
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	e20080e7          	jalr	-480(ra) # 80003a94 <brelse>
  bp = bread(dev, bno);
    80003c7c:	85a6                	mv	a1,s1
    80003c7e:	855e                	mv	a0,s7
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	ce4080e7          	jalr	-796(ra) # 80003964 <bread>
    80003c88:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003c8a:	40000613          	li	a2,1024
    80003c8e:	4581                	li	a1,0
    80003c90:	05850513          	add	a0,a0,88
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	0a0080e7          	jalr	160(ra) # 80000d34 <memset>
  log_write(bp);
    80003c9c:	854a                	mv	a0,s2
    80003c9e:	00001097          	auipc	ra,0x1
    80003ca2:	0a0080e7          	jalr	160(ra) # 80004d3e <log_write>
  brelse(bp);
    80003ca6:	854a                	mv	a0,s2
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	dec080e7          	jalr	-532(ra) # 80003a94 <brelse>
}
    80003cb0:	6906                	ld	s2,64(sp)
    80003cb2:	79e2                	ld	s3,56(sp)
    80003cb4:	7a42                	ld	s4,48(sp)
    80003cb6:	7aa2                	ld	s5,40(sp)
    80003cb8:	7b02                	ld	s6,32(sp)
    80003cba:	6be2                	ld	s7,24(sp)
    80003cbc:	6c42                	ld	s8,16(sp)
    80003cbe:	6ca2                	ld	s9,8(sp)
}
    80003cc0:	8526                	mv	a0,s1
    80003cc2:	60e6                	ld	ra,88(sp)
    80003cc4:	6446                	ld	s0,80(sp)
    80003cc6:	64a6                	ld	s1,72(sp)
    80003cc8:	6125                	add	sp,sp,96
    80003cca:	8082                	ret
    brelse(bp);
    80003ccc:	854a                	mv	a0,s2
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	dc6080e7          	jalr	-570(ra) # 80003a94 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003cd6:	015c87bb          	addw	a5,s9,s5
    80003cda:	00078a9b          	sext.w	s5,a5
    80003cde:	004b2703          	lw	a4,4(s6)
    80003ce2:	06eaf163          	bgeu	s5,a4,80003d44 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
    80003ce6:	41fad79b          	sraw	a5,s5,0x1f
    80003cea:	0137d79b          	srlw	a5,a5,0x13
    80003cee:	015787bb          	addw	a5,a5,s5
    80003cf2:	40d7d79b          	sraw	a5,a5,0xd
    80003cf6:	01cb2583          	lw	a1,28(s6)
    80003cfa:	9dbd                	addw	a1,a1,a5
    80003cfc:	855e                	mv	a0,s7
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	c66080e7          	jalr	-922(ra) # 80003964 <bread>
    80003d06:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d08:	004b2503          	lw	a0,4(s6)
    80003d0c:	000a849b          	sext.w	s1,s5
    80003d10:	8762                	mv	a4,s8
    80003d12:	faa4fde3          	bgeu	s1,a0,80003ccc <balloc+0xa8>
      m = 1 << (bi % 8);
    80003d16:	00777693          	and	a3,a4,7
    80003d1a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003d1e:	41f7579b          	sraw	a5,a4,0x1f
    80003d22:	01d7d79b          	srlw	a5,a5,0x1d
    80003d26:	9fb9                	addw	a5,a5,a4
    80003d28:	4037d79b          	sraw	a5,a5,0x3
    80003d2c:	00f90633          	add	a2,s2,a5
    80003d30:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003d34:	00c6f5b3          	and	a1,a3,a2
    80003d38:	d585                	beqz	a1,80003c60 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d3a:	2705                	addw	a4,a4,1
    80003d3c:	2485                	addw	s1,s1,1
    80003d3e:	fd471ae3          	bne	a4,s4,80003d12 <balloc+0xee>
    80003d42:	b769                	j	80003ccc <balloc+0xa8>
    80003d44:	6906                	ld	s2,64(sp)
    80003d46:	79e2                	ld	s3,56(sp)
    80003d48:	7a42                	ld	s4,48(sp)
    80003d4a:	7aa2                	ld	s5,40(sp)
    80003d4c:	7b02                	ld	s6,32(sp)
    80003d4e:	6be2                	ld	s7,24(sp)
    80003d50:	6c42                	ld	s8,16(sp)
    80003d52:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80003d54:	00006517          	auipc	a0,0x6
    80003d58:	88c50513          	add	a0,a0,-1908 # 800095e0 <etext+0x5e0>
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	84e080e7          	jalr	-1970(ra) # 800005aa <printf>
  return 0;
    80003d64:	4481                	li	s1,0
    80003d66:	bfa9                	j	80003cc0 <balloc+0x9c>

0000000080003d68 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003d68:	7179                	add	sp,sp,-48
    80003d6a:	f406                	sd	ra,40(sp)
    80003d6c:	f022                	sd	s0,32(sp)
    80003d6e:	ec26                	sd	s1,24(sp)
    80003d70:	e84a                	sd	s2,16(sp)
    80003d72:	e44e                	sd	s3,8(sp)
    80003d74:	1800                	add	s0,sp,48
    80003d76:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003d78:	47ad                	li	a5,11
    80003d7a:	02b7e863          	bltu	a5,a1,80003daa <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003d7e:	02059793          	sll	a5,a1,0x20
    80003d82:	01e7d593          	srl	a1,a5,0x1e
    80003d86:	00b504b3          	add	s1,a0,a1
    80003d8a:	0504a903          	lw	s2,80(s1)
    80003d8e:	08091263          	bnez	s2,80003e12 <bmap+0xaa>
      addr = balloc(ip->dev);
    80003d92:	4108                	lw	a0,0(a0)
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	e90080e7          	jalr	-368(ra) # 80003c24 <balloc>
    80003d9c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003da0:	06090963          	beqz	s2,80003e12 <bmap+0xaa>
        return 0;
      ip->addrs[bn] = addr;
    80003da4:	0524a823          	sw	s2,80(s1)
    80003da8:	a0ad                	j	80003e12 <bmap+0xaa>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003daa:	ff45849b          	addw	s1,a1,-12
    80003dae:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003db2:	0ff00793          	li	a5,255
    80003db6:	08e7e863          	bltu	a5,a4,80003e46 <bmap+0xde>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003dba:	08052903          	lw	s2,128(a0)
    80003dbe:	00091f63          	bnez	s2,80003ddc <bmap+0x74>
      addr = balloc(ip->dev);
    80003dc2:	4108                	lw	a0,0(a0)
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	e60080e7          	jalr	-416(ra) # 80003c24 <balloc>
    80003dcc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003dd0:	04090163          	beqz	s2,80003e12 <bmap+0xaa>
    80003dd4:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003dd6:	0929a023          	sw	s2,128(s3)
    80003dda:	a011                	j	80003dde <bmap+0x76>
    80003ddc:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80003dde:	85ca                	mv	a1,s2
    80003de0:	0009a503          	lw	a0,0(s3)
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	b80080e7          	jalr	-1152(ra) # 80003964 <bread>
    80003dec:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003dee:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    80003df2:	02049713          	sll	a4,s1,0x20
    80003df6:	01e75593          	srl	a1,a4,0x1e
    80003dfa:	00b784b3          	add	s1,a5,a1
    80003dfe:	0004a903          	lw	s2,0(s1)
    80003e02:	02090063          	beqz	s2,80003e22 <bmap+0xba>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003e06:	8552                	mv	a0,s4
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	c8c080e7          	jalr	-884(ra) # 80003a94 <brelse>
    return addr;
    80003e10:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003e12:	854a                	mv	a0,s2
    80003e14:	70a2                	ld	ra,40(sp)
    80003e16:	7402                	ld	s0,32(sp)
    80003e18:	64e2                	ld	s1,24(sp)
    80003e1a:	6942                	ld	s2,16(sp)
    80003e1c:	69a2                	ld	s3,8(sp)
    80003e1e:	6145                	add	sp,sp,48
    80003e20:	8082                	ret
      addr = balloc(ip->dev);
    80003e22:	0009a503          	lw	a0,0(s3)
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	dfe080e7          	jalr	-514(ra) # 80003c24 <balloc>
    80003e2e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003e32:	fc090ae3          	beqz	s2,80003e06 <bmap+0x9e>
        a[bn] = addr;
    80003e36:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003e3a:	8552                	mv	a0,s4
    80003e3c:	00001097          	auipc	ra,0x1
    80003e40:	f02080e7          	jalr	-254(ra) # 80004d3e <log_write>
    80003e44:	b7c9                	j	80003e06 <bmap+0x9e>
    80003e46:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80003e48:	00005517          	auipc	a0,0x5
    80003e4c:	7b050513          	add	a0,a0,1968 # 800095f8 <etext+0x5f8>
    80003e50:	ffffc097          	auipc	ra,0xffffc
    80003e54:	710080e7          	jalr	1808(ra) # 80000560 <panic>

0000000080003e58 <iget>:
{
    80003e58:	7179                	add	sp,sp,-48
    80003e5a:	f406                	sd	ra,40(sp)
    80003e5c:	f022                	sd	s0,32(sp)
    80003e5e:	ec26                	sd	s1,24(sp)
    80003e60:	e84a                	sd	s2,16(sp)
    80003e62:	e44e                	sd	s3,8(sp)
    80003e64:	e052                	sd	s4,0(sp)
    80003e66:	1800                	add	s0,sp,48
    80003e68:	89aa                	mv	s3,a0
    80003e6a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003e6c:	0001e517          	auipc	a0,0x1e
    80003e70:	b2c50513          	add	a0,a0,-1236 # 80021998 <itable>
    80003e74:	ffffd097          	auipc	ra,0xffffd
    80003e78:	dc4080e7          	jalr	-572(ra) # 80000c38 <acquire>
  empty = 0;
    80003e7c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e7e:	0001e497          	auipc	s1,0x1e
    80003e82:	b3248493          	add	s1,s1,-1230 # 800219b0 <itable+0x18>
    80003e86:	0001f697          	auipc	a3,0x1f
    80003e8a:	5ba68693          	add	a3,a3,1466 # 80023440 <log>
    80003e8e:	a039                	j	80003e9c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e90:	02090b63          	beqz	s2,80003ec6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e94:	08848493          	add	s1,s1,136
    80003e98:	02d48a63          	beq	s1,a3,80003ecc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003e9c:	449c                	lw	a5,8(s1)
    80003e9e:	fef059e3          	blez	a5,80003e90 <iget+0x38>
    80003ea2:	4098                	lw	a4,0(s1)
    80003ea4:	ff3716e3          	bne	a4,s3,80003e90 <iget+0x38>
    80003ea8:	40d8                	lw	a4,4(s1)
    80003eaa:	ff4713e3          	bne	a4,s4,80003e90 <iget+0x38>
      ip->ref++;
    80003eae:	2785                	addw	a5,a5,1
    80003eb0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003eb2:	0001e517          	auipc	a0,0x1e
    80003eb6:	ae650513          	add	a0,a0,-1306 # 80021998 <itable>
    80003eba:	ffffd097          	auipc	ra,0xffffd
    80003ebe:	e32080e7          	jalr	-462(ra) # 80000cec <release>
      return ip;
    80003ec2:	8926                	mv	s2,s1
    80003ec4:	a03d                	j	80003ef2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ec6:	f7f9                	bnez	a5,80003e94 <iget+0x3c>
      empty = ip;
    80003ec8:	8926                	mv	s2,s1
    80003eca:	b7e9                	j	80003e94 <iget+0x3c>
  if(empty == 0)
    80003ecc:	02090c63          	beqz	s2,80003f04 <iget+0xac>
  ip->dev = dev;
    80003ed0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ed4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ed8:	4785                	li	a5,1
    80003eda:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ede:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ee2:	0001e517          	auipc	a0,0x1e
    80003ee6:	ab650513          	add	a0,a0,-1354 # 80021998 <itable>
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	e02080e7          	jalr	-510(ra) # 80000cec <release>
}
    80003ef2:	854a                	mv	a0,s2
    80003ef4:	70a2                	ld	ra,40(sp)
    80003ef6:	7402                	ld	s0,32(sp)
    80003ef8:	64e2                	ld	s1,24(sp)
    80003efa:	6942                	ld	s2,16(sp)
    80003efc:	69a2                	ld	s3,8(sp)
    80003efe:	6a02                	ld	s4,0(sp)
    80003f00:	6145                	add	sp,sp,48
    80003f02:	8082                	ret
    panic("iget: no inodes");
    80003f04:	00005517          	auipc	a0,0x5
    80003f08:	70c50513          	add	a0,a0,1804 # 80009610 <etext+0x610>
    80003f0c:	ffffc097          	auipc	ra,0xffffc
    80003f10:	654080e7          	jalr	1620(ra) # 80000560 <panic>

0000000080003f14 <fsinit>:
fsinit(int dev) {
    80003f14:	7179                	add	sp,sp,-48
    80003f16:	f406                	sd	ra,40(sp)
    80003f18:	f022                	sd	s0,32(sp)
    80003f1a:	ec26                	sd	s1,24(sp)
    80003f1c:	e84a                	sd	s2,16(sp)
    80003f1e:	e44e                	sd	s3,8(sp)
    80003f20:	1800                	add	s0,sp,48
    80003f22:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003f24:	4585                	li	a1,1
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	a3e080e7          	jalr	-1474(ra) # 80003964 <bread>
    80003f2e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003f30:	0001e997          	auipc	s3,0x1e
    80003f34:	a4898993          	add	s3,s3,-1464 # 80021978 <sb>
    80003f38:	02000613          	li	a2,32
    80003f3c:	05850593          	add	a1,a0,88
    80003f40:	854e                	mv	a0,s3
    80003f42:	ffffd097          	auipc	ra,0xffffd
    80003f46:	e4e080e7          	jalr	-434(ra) # 80000d90 <memmove>
  brelse(bp);
    80003f4a:	8526                	mv	a0,s1
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	b48080e7          	jalr	-1208(ra) # 80003a94 <brelse>
  if(sb.magic != FSMAGIC)
    80003f54:	0009a703          	lw	a4,0(s3)
    80003f58:	102037b7          	lui	a5,0x10203
    80003f5c:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003f60:	02f71263          	bne	a4,a5,80003f84 <fsinit+0x70>
  initlog(dev, &sb);
    80003f64:	0001e597          	auipc	a1,0x1e
    80003f68:	a1458593          	add	a1,a1,-1516 # 80021978 <sb>
    80003f6c:	854a                	mv	a0,s2
    80003f6e:	00001097          	auipc	ra,0x1
    80003f72:	b60080e7          	jalr	-1184(ra) # 80004ace <initlog>
}
    80003f76:	70a2                	ld	ra,40(sp)
    80003f78:	7402                	ld	s0,32(sp)
    80003f7a:	64e2                	ld	s1,24(sp)
    80003f7c:	6942                	ld	s2,16(sp)
    80003f7e:	69a2                	ld	s3,8(sp)
    80003f80:	6145                	add	sp,sp,48
    80003f82:	8082                	ret
    panic("invalid file system");
    80003f84:	00005517          	auipc	a0,0x5
    80003f88:	69c50513          	add	a0,a0,1692 # 80009620 <etext+0x620>
    80003f8c:	ffffc097          	auipc	ra,0xffffc
    80003f90:	5d4080e7          	jalr	1492(ra) # 80000560 <panic>

0000000080003f94 <iinit>:
{
    80003f94:	7179                	add	sp,sp,-48
    80003f96:	f406                	sd	ra,40(sp)
    80003f98:	f022                	sd	s0,32(sp)
    80003f9a:	ec26                	sd	s1,24(sp)
    80003f9c:	e84a                	sd	s2,16(sp)
    80003f9e:	e44e                	sd	s3,8(sp)
    80003fa0:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003fa2:	00005597          	auipc	a1,0x5
    80003fa6:	69658593          	add	a1,a1,1686 # 80009638 <etext+0x638>
    80003faa:	0001e517          	auipc	a0,0x1e
    80003fae:	9ee50513          	add	a0,a0,-1554 # 80021998 <itable>
    80003fb2:	ffffd097          	auipc	ra,0xffffd
    80003fb6:	bf6080e7          	jalr	-1034(ra) # 80000ba8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003fba:	0001e497          	auipc	s1,0x1e
    80003fbe:	a0648493          	add	s1,s1,-1530 # 800219c0 <itable+0x28>
    80003fc2:	0001f997          	auipc	s3,0x1f
    80003fc6:	48e98993          	add	s3,s3,1166 # 80023450 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003fca:	00005917          	auipc	s2,0x5
    80003fce:	67690913          	add	s2,s2,1654 # 80009640 <etext+0x640>
    80003fd2:	85ca                	mv	a1,s2
    80003fd4:	8526                	mv	a0,s1
    80003fd6:	00001097          	auipc	ra,0x1
    80003fda:	e4c080e7          	jalr	-436(ra) # 80004e22 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003fde:	08848493          	add	s1,s1,136
    80003fe2:	ff3498e3          	bne	s1,s3,80003fd2 <iinit+0x3e>
}
    80003fe6:	70a2                	ld	ra,40(sp)
    80003fe8:	7402                	ld	s0,32(sp)
    80003fea:	64e2                	ld	s1,24(sp)
    80003fec:	6942                	ld	s2,16(sp)
    80003fee:	69a2                	ld	s3,8(sp)
    80003ff0:	6145                	add	sp,sp,48
    80003ff2:	8082                	ret

0000000080003ff4 <ialloc>:
{
    80003ff4:	7139                	add	sp,sp,-64
    80003ff6:	fc06                	sd	ra,56(sp)
    80003ff8:	f822                	sd	s0,48(sp)
    80003ffa:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ffc:	0001e717          	auipc	a4,0x1e
    80004000:	98872703          	lw	a4,-1656(a4) # 80021984 <sb+0xc>
    80004004:	4785                	li	a5,1
    80004006:	06e7f463          	bgeu	a5,a4,8000406e <ialloc+0x7a>
    8000400a:	f426                	sd	s1,40(sp)
    8000400c:	f04a                	sd	s2,32(sp)
    8000400e:	ec4e                	sd	s3,24(sp)
    80004010:	e852                	sd	s4,16(sp)
    80004012:	e456                	sd	s5,8(sp)
    80004014:	e05a                	sd	s6,0(sp)
    80004016:	8aaa                	mv	s5,a0
    80004018:	8b2e                	mv	s6,a1
    8000401a:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000401c:	0001ea17          	auipc	s4,0x1e
    80004020:	95ca0a13          	add	s4,s4,-1700 # 80021978 <sb>
    80004024:	00495593          	srl	a1,s2,0x4
    80004028:	018a2783          	lw	a5,24(s4)
    8000402c:	9dbd                	addw	a1,a1,a5
    8000402e:	8556                	mv	a0,s5
    80004030:	00000097          	auipc	ra,0x0
    80004034:	934080e7          	jalr	-1740(ra) # 80003964 <bread>
    80004038:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000403a:	05850993          	add	s3,a0,88
    8000403e:	00f97793          	and	a5,s2,15
    80004042:	079a                	sll	a5,a5,0x6
    80004044:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004046:	00099783          	lh	a5,0(s3)
    8000404a:	cf9d                	beqz	a5,80004088 <ialloc+0x94>
    brelse(bp);
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	a48080e7          	jalr	-1464(ra) # 80003a94 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004054:	0905                	add	s2,s2,1
    80004056:	00ca2703          	lw	a4,12(s4)
    8000405a:	0009079b          	sext.w	a5,s2
    8000405e:	fce7e3e3          	bltu	a5,a4,80004024 <ialloc+0x30>
    80004062:	74a2                	ld	s1,40(sp)
    80004064:	7902                	ld	s2,32(sp)
    80004066:	69e2                	ld	s3,24(sp)
    80004068:	6a42                	ld	s4,16(sp)
    8000406a:	6aa2                	ld	s5,8(sp)
    8000406c:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    8000406e:	00005517          	auipc	a0,0x5
    80004072:	5da50513          	add	a0,a0,1498 # 80009648 <etext+0x648>
    80004076:	ffffc097          	auipc	ra,0xffffc
    8000407a:	534080e7          	jalr	1332(ra) # 800005aa <printf>
  return 0;
    8000407e:	4501                	li	a0,0
}
    80004080:	70e2                	ld	ra,56(sp)
    80004082:	7442                	ld	s0,48(sp)
    80004084:	6121                	add	sp,sp,64
    80004086:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004088:	04000613          	li	a2,64
    8000408c:	4581                	li	a1,0
    8000408e:	854e                	mv	a0,s3
    80004090:	ffffd097          	auipc	ra,0xffffd
    80004094:	ca4080e7          	jalr	-860(ra) # 80000d34 <memset>
      dip->type = type;
    80004098:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000409c:	8526                	mv	a0,s1
    8000409e:	00001097          	auipc	ra,0x1
    800040a2:	ca0080e7          	jalr	-864(ra) # 80004d3e <log_write>
      brelse(bp);
    800040a6:	8526                	mv	a0,s1
    800040a8:	00000097          	auipc	ra,0x0
    800040ac:	9ec080e7          	jalr	-1556(ra) # 80003a94 <brelse>
      return iget(dev, inum);
    800040b0:	0009059b          	sext.w	a1,s2
    800040b4:	8556                	mv	a0,s5
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	da2080e7          	jalr	-606(ra) # 80003e58 <iget>
    800040be:	74a2                	ld	s1,40(sp)
    800040c0:	7902                	ld	s2,32(sp)
    800040c2:	69e2                	ld	s3,24(sp)
    800040c4:	6a42                	ld	s4,16(sp)
    800040c6:	6aa2                	ld	s5,8(sp)
    800040c8:	6b02                	ld	s6,0(sp)
    800040ca:	bf5d                	j	80004080 <ialloc+0x8c>

00000000800040cc <iupdate>:
{
    800040cc:	1101                	add	sp,sp,-32
    800040ce:	ec06                	sd	ra,24(sp)
    800040d0:	e822                	sd	s0,16(sp)
    800040d2:	e426                	sd	s1,8(sp)
    800040d4:	e04a                	sd	s2,0(sp)
    800040d6:	1000                	add	s0,sp,32
    800040d8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800040da:	415c                	lw	a5,4(a0)
    800040dc:	0047d79b          	srlw	a5,a5,0x4
    800040e0:	0001e597          	auipc	a1,0x1e
    800040e4:	8b05a583          	lw	a1,-1872(a1) # 80021990 <sb+0x18>
    800040e8:	9dbd                	addw	a1,a1,a5
    800040ea:	4108                	lw	a0,0(a0)
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	878080e7          	jalr	-1928(ra) # 80003964 <bread>
    800040f4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040f6:	05850793          	add	a5,a0,88
    800040fa:	40d8                	lw	a4,4(s1)
    800040fc:	8b3d                	and	a4,a4,15
    800040fe:	071a                	sll	a4,a4,0x6
    80004100:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80004102:	04449703          	lh	a4,68(s1)
    80004106:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000410a:	04649703          	lh	a4,70(s1)
    8000410e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80004112:	04849703          	lh	a4,72(s1)
    80004116:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000411a:	04a49703          	lh	a4,74(s1)
    8000411e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80004122:	44f8                	lw	a4,76(s1)
    80004124:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004126:	03400613          	li	a2,52
    8000412a:	05048593          	add	a1,s1,80
    8000412e:	00c78513          	add	a0,a5,12
    80004132:	ffffd097          	auipc	ra,0xffffd
    80004136:	c5e080e7          	jalr	-930(ra) # 80000d90 <memmove>
  log_write(bp);
    8000413a:	854a                	mv	a0,s2
    8000413c:	00001097          	auipc	ra,0x1
    80004140:	c02080e7          	jalr	-1022(ra) # 80004d3e <log_write>
  brelse(bp);
    80004144:	854a                	mv	a0,s2
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	94e080e7          	jalr	-1714(ra) # 80003a94 <brelse>
}
    8000414e:	60e2                	ld	ra,24(sp)
    80004150:	6442                	ld	s0,16(sp)
    80004152:	64a2                	ld	s1,8(sp)
    80004154:	6902                	ld	s2,0(sp)
    80004156:	6105                	add	sp,sp,32
    80004158:	8082                	ret

000000008000415a <idup>:
{
    8000415a:	1101                	add	sp,sp,-32
    8000415c:	ec06                	sd	ra,24(sp)
    8000415e:	e822                	sd	s0,16(sp)
    80004160:	e426                	sd	s1,8(sp)
    80004162:	1000                	add	s0,sp,32
    80004164:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004166:	0001e517          	auipc	a0,0x1e
    8000416a:	83250513          	add	a0,a0,-1998 # 80021998 <itable>
    8000416e:	ffffd097          	auipc	ra,0xffffd
    80004172:	aca080e7          	jalr	-1334(ra) # 80000c38 <acquire>
  ip->ref++;
    80004176:	449c                	lw	a5,8(s1)
    80004178:	2785                	addw	a5,a5,1
    8000417a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000417c:	0001e517          	auipc	a0,0x1e
    80004180:	81c50513          	add	a0,a0,-2020 # 80021998 <itable>
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	b68080e7          	jalr	-1176(ra) # 80000cec <release>
}
    8000418c:	8526                	mv	a0,s1
    8000418e:	60e2                	ld	ra,24(sp)
    80004190:	6442                	ld	s0,16(sp)
    80004192:	64a2                	ld	s1,8(sp)
    80004194:	6105                	add	sp,sp,32
    80004196:	8082                	ret

0000000080004198 <ilock>:
{
    80004198:	1101                	add	sp,sp,-32
    8000419a:	ec06                	sd	ra,24(sp)
    8000419c:	e822                	sd	s0,16(sp)
    8000419e:	e426                	sd	s1,8(sp)
    800041a0:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800041a2:	c10d                	beqz	a0,800041c4 <ilock+0x2c>
    800041a4:	84aa                	mv	s1,a0
    800041a6:	451c                	lw	a5,8(a0)
    800041a8:	00f05e63          	blez	a5,800041c4 <ilock+0x2c>
  acquiresleep(&ip->lock);
    800041ac:	0541                	add	a0,a0,16
    800041ae:	00001097          	auipc	ra,0x1
    800041b2:	cae080e7          	jalr	-850(ra) # 80004e5c <acquiresleep>
  if(ip->valid == 0){
    800041b6:	40bc                	lw	a5,64(s1)
    800041b8:	cf99                	beqz	a5,800041d6 <ilock+0x3e>
}
    800041ba:	60e2                	ld	ra,24(sp)
    800041bc:	6442                	ld	s0,16(sp)
    800041be:	64a2                	ld	s1,8(sp)
    800041c0:	6105                	add	sp,sp,32
    800041c2:	8082                	ret
    800041c4:	e04a                	sd	s2,0(sp)
    panic("ilock");
    800041c6:	00005517          	auipc	a0,0x5
    800041ca:	49a50513          	add	a0,a0,1178 # 80009660 <etext+0x660>
    800041ce:	ffffc097          	auipc	ra,0xffffc
    800041d2:	392080e7          	jalr	914(ra) # 80000560 <panic>
    800041d6:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041d8:	40dc                	lw	a5,4(s1)
    800041da:	0047d79b          	srlw	a5,a5,0x4
    800041de:	0001d597          	auipc	a1,0x1d
    800041e2:	7b25a583          	lw	a1,1970(a1) # 80021990 <sb+0x18>
    800041e6:	9dbd                	addw	a1,a1,a5
    800041e8:	4088                	lw	a0,0(s1)
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	77a080e7          	jalr	1914(ra) # 80003964 <bread>
    800041f2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800041f4:	05850593          	add	a1,a0,88
    800041f8:	40dc                	lw	a5,4(s1)
    800041fa:	8bbd                	and	a5,a5,15
    800041fc:	079a                	sll	a5,a5,0x6
    800041fe:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004200:	00059783          	lh	a5,0(a1)
    80004204:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004208:	00259783          	lh	a5,2(a1)
    8000420c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004210:	00459783          	lh	a5,4(a1)
    80004214:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004218:	00659783          	lh	a5,6(a1)
    8000421c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004220:	459c                	lw	a5,8(a1)
    80004222:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004224:	03400613          	li	a2,52
    80004228:	05b1                	add	a1,a1,12
    8000422a:	05048513          	add	a0,s1,80
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	b62080e7          	jalr	-1182(ra) # 80000d90 <memmove>
    brelse(bp);
    80004236:	854a                	mv	a0,s2
    80004238:	00000097          	auipc	ra,0x0
    8000423c:	85c080e7          	jalr	-1956(ra) # 80003a94 <brelse>
    ip->valid = 1;
    80004240:	4785                	li	a5,1
    80004242:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004244:	04449783          	lh	a5,68(s1)
    80004248:	c399                	beqz	a5,8000424e <ilock+0xb6>
    8000424a:	6902                	ld	s2,0(sp)
    8000424c:	b7bd                	j	800041ba <ilock+0x22>
      panic("ilock: no type");
    8000424e:	00005517          	auipc	a0,0x5
    80004252:	41a50513          	add	a0,a0,1050 # 80009668 <etext+0x668>
    80004256:	ffffc097          	auipc	ra,0xffffc
    8000425a:	30a080e7          	jalr	778(ra) # 80000560 <panic>

000000008000425e <iunlock>:
{
    8000425e:	1101                	add	sp,sp,-32
    80004260:	ec06                	sd	ra,24(sp)
    80004262:	e822                	sd	s0,16(sp)
    80004264:	e426                	sd	s1,8(sp)
    80004266:	e04a                	sd	s2,0(sp)
    80004268:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000426a:	c905                	beqz	a0,8000429a <iunlock+0x3c>
    8000426c:	84aa                	mv	s1,a0
    8000426e:	01050913          	add	s2,a0,16
    80004272:	854a                	mv	a0,s2
    80004274:	00001097          	auipc	ra,0x1
    80004278:	c82080e7          	jalr	-894(ra) # 80004ef6 <holdingsleep>
    8000427c:	cd19                	beqz	a0,8000429a <iunlock+0x3c>
    8000427e:	449c                	lw	a5,8(s1)
    80004280:	00f05d63          	blez	a5,8000429a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004284:	854a                	mv	a0,s2
    80004286:	00001097          	auipc	ra,0x1
    8000428a:	c2c080e7          	jalr	-980(ra) # 80004eb2 <releasesleep>
}
    8000428e:	60e2                	ld	ra,24(sp)
    80004290:	6442                	ld	s0,16(sp)
    80004292:	64a2                	ld	s1,8(sp)
    80004294:	6902                	ld	s2,0(sp)
    80004296:	6105                	add	sp,sp,32
    80004298:	8082                	ret
    panic("iunlock");
    8000429a:	00005517          	auipc	a0,0x5
    8000429e:	3de50513          	add	a0,a0,990 # 80009678 <etext+0x678>
    800042a2:	ffffc097          	auipc	ra,0xffffc
    800042a6:	2be080e7          	jalr	702(ra) # 80000560 <panic>

00000000800042aa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800042aa:	7179                	add	sp,sp,-48
    800042ac:	f406                	sd	ra,40(sp)
    800042ae:	f022                	sd	s0,32(sp)
    800042b0:	ec26                	sd	s1,24(sp)
    800042b2:	e84a                	sd	s2,16(sp)
    800042b4:	e44e                	sd	s3,8(sp)
    800042b6:	1800                	add	s0,sp,48
    800042b8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800042ba:	05050493          	add	s1,a0,80
    800042be:	08050913          	add	s2,a0,128
    800042c2:	a021                	j	800042ca <itrunc+0x20>
    800042c4:	0491                	add	s1,s1,4
    800042c6:	01248d63          	beq	s1,s2,800042e0 <itrunc+0x36>
    if(ip->addrs[i]){
    800042ca:	408c                	lw	a1,0(s1)
    800042cc:	dde5                	beqz	a1,800042c4 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    800042ce:	0009a503          	lw	a0,0(s3)
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	8d6080e7          	jalr	-1834(ra) # 80003ba8 <bfree>
      ip->addrs[i] = 0;
    800042da:	0004a023          	sw	zero,0(s1)
    800042de:	b7dd                	j	800042c4 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    800042e0:	0809a583          	lw	a1,128(s3)
    800042e4:	ed99                	bnez	a1,80004302 <itrunc+0x58>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800042e6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800042ea:	854e                	mv	a0,s3
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	de0080e7          	jalr	-544(ra) # 800040cc <iupdate>
}
    800042f4:	70a2                	ld	ra,40(sp)
    800042f6:	7402                	ld	s0,32(sp)
    800042f8:	64e2                	ld	s1,24(sp)
    800042fa:	6942                	ld	s2,16(sp)
    800042fc:	69a2                	ld	s3,8(sp)
    800042fe:	6145                	add	sp,sp,48
    80004300:	8082                	ret
    80004302:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004304:	0009a503          	lw	a0,0(s3)
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	65c080e7          	jalr	1628(ra) # 80003964 <bread>
    80004310:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004312:	05850493          	add	s1,a0,88
    80004316:	45850913          	add	s2,a0,1112
    8000431a:	a021                	j	80004322 <itrunc+0x78>
    8000431c:	0491                	add	s1,s1,4
    8000431e:	01248b63          	beq	s1,s2,80004334 <itrunc+0x8a>
      if(a[j])
    80004322:	408c                	lw	a1,0(s1)
    80004324:	dde5                	beqz	a1,8000431c <itrunc+0x72>
        bfree(ip->dev, a[j]);
    80004326:	0009a503          	lw	a0,0(s3)
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	87e080e7          	jalr	-1922(ra) # 80003ba8 <bfree>
    80004332:	b7ed                	j	8000431c <itrunc+0x72>
    brelse(bp);
    80004334:	8552                	mv	a0,s4
    80004336:	fffff097          	auipc	ra,0xfffff
    8000433a:	75e080e7          	jalr	1886(ra) # 80003a94 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000433e:	0809a583          	lw	a1,128(s3)
    80004342:	0009a503          	lw	a0,0(s3)
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	862080e7          	jalr	-1950(ra) # 80003ba8 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000434e:	0809a023          	sw	zero,128(s3)
    80004352:	6a02                	ld	s4,0(sp)
    80004354:	bf49                	j	800042e6 <itrunc+0x3c>

0000000080004356 <iput>:
{
    80004356:	1101                	add	sp,sp,-32
    80004358:	ec06                	sd	ra,24(sp)
    8000435a:	e822                	sd	s0,16(sp)
    8000435c:	e426                	sd	s1,8(sp)
    8000435e:	1000                	add	s0,sp,32
    80004360:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004362:	0001d517          	auipc	a0,0x1d
    80004366:	63650513          	add	a0,a0,1590 # 80021998 <itable>
    8000436a:	ffffd097          	auipc	ra,0xffffd
    8000436e:	8ce080e7          	jalr	-1842(ra) # 80000c38 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004372:	4498                	lw	a4,8(s1)
    80004374:	4785                	li	a5,1
    80004376:	02f70263          	beq	a4,a5,8000439a <iput+0x44>
  ip->ref--;
    8000437a:	449c                	lw	a5,8(s1)
    8000437c:	37fd                	addw	a5,a5,-1
    8000437e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004380:	0001d517          	auipc	a0,0x1d
    80004384:	61850513          	add	a0,a0,1560 # 80021998 <itable>
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	964080e7          	jalr	-1692(ra) # 80000cec <release>
}
    80004390:	60e2                	ld	ra,24(sp)
    80004392:	6442                	ld	s0,16(sp)
    80004394:	64a2                	ld	s1,8(sp)
    80004396:	6105                	add	sp,sp,32
    80004398:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000439a:	40bc                	lw	a5,64(s1)
    8000439c:	dff9                	beqz	a5,8000437a <iput+0x24>
    8000439e:	04a49783          	lh	a5,74(s1)
    800043a2:	ffe1                	bnez	a5,8000437a <iput+0x24>
    800043a4:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    800043a6:	01048913          	add	s2,s1,16
    800043aa:	854a                	mv	a0,s2
    800043ac:	00001097          	auipc	ra,0x1
    800043b0:	ab0080e7          	jalr	-1360(ra) # 80004e5c <acquiresleep>
    release(&itable.lock);
    800043b4:	0001d517          	auipc	a0,0x1d
    800043b8:	5e450513          	add	a0,a0,1508 # 80021998 <itable>
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	930080e7          	jalr	-1744(ra) # 80000cec <release>
    itrunc(ip);
    800043c4:	8526                	mv	a0,s1
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	ee4080e7          	jalr	-284(ra) # 800042aa <itrunc>
    ip->type = 0;
    800043ce:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800043d2:	8526                	mv	a0,s1
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	cf8080e7          	jalr	-776(ra) # 800040cc <iupdate>
    ip->valid = 0;
    800043dc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800043e0:	854a                	mv	a0,s2
    800043e2:	00001097          	auipc	ra,0x1
    800043e6:	ad0080e7          	jalr	-1328(ra) # 80004eb2 <releasesleep>
    acquire(&itable.lock);
    800043ea:	0001d517          	auipc	a0,0x1d
    800043ee:	5ae50513          	add	a0,a0,1454 # 80021998 <itable>
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	846080e7          	jalr	-1978(ra) # 80000c38 <acquire>
    800043fa:	6902                	ld	s2,0(sp)
    800043fc:	bfbd                	j	8000437a <iput+0x24>

00000000800043fe <iunlockput>:
{
    800043fe:	1101                	add	sp,sp,-32
    80004400:	ec06                	sd	ra,24(sp)
    80004402:	e822                	sd	s0,16(sp)
    80004404:	e426                	sd	s1,8(sp)
    80004406:	1000                	add	s0,sp,32
    80004408:	84aa                	mv	s1,a0
  iunlock(ip);
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	e54080e7          	jalr	-428(ra) # 8000425e <iunlock>
  iput(ip);
    80004412:	8526                	mv	a0,s1
    80004414:	00000097          	auipc	ra,0x0
    80004418:	f42080e7          	jalr	-190(ra) # 80004356 <iput>
}
    8000441c:	60e2                	ld	ra,24(sp)
    8000441e:	6442                	ld	s0,16(sp)
    80004420:	64a2                	ld	s1,8(sp)
    80004422:	6105                	add	sp,sp,32
    80004424:	8082                	ret

0000000080004426 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004426:	1141                	add	sp,sp,-16
    80004428:	e422                	sd	s0,8(sp)
    8000442a:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    8000442c:	411c                	lw	a5,0(a0)
    8000442e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004430:	415c                	lw	a5,4(a0)
    80004432:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004434:	04451783          	lh	a5,68(a0)
    80004438:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000443c:	04a51783          	lh	a5,74(a0)
    80004440:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004444:	04c56783          	lwu	a5,76(a0)
    80004448:	e99c                	sd	a5,16(a1)
}
    8000444a:	6422                	ld	s0,8(sp)
    8000444c:	0141                	add	sp,sp,16
    8000444e:	8082                	ret

0000000080004450 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004450:	457c                	lw	a5,76(a0)
    80004452:	10d7e563          	bltu	a5,a3,8000455c <readi+0x10c>
{
    80004456:	7159                	add	sp,sp,-112
    80004458:	f486                	sd	ra,104(sp)
    8000445a:	f0a2                	sd	s0,96(sp)
    8000445c:	eca6                	sd	s1,88(sp)
    8000445e:	e0d2                	sd	s4,64(sp)
    80004460:	fc56                	sd	s5,56(sp)
    80004462:	f85a                	sd	s6,48(sp)
    80004464:	f45e                	sd	s7,40(sp)
    80004466:	1880                	add	s0,sp,112
    80004468:	8b2a                	mv	s6,a0
    8000446a:	8bae                	mv	s7,a1
    8000446c:	8a32                	mv	s4,a2
    8000446e:	84b6                	mv	s1,a3
    80004470:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004472:	9f35                	addw	a4,a4,a3
    return 0;
    80004474:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004476:	0cd76a63          	bltu	a4,a3,8000454a <readi+0xfa>
    8000447a:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    8000447c:	00e7f463          	bgeu	a5,a4,80004484 <readi+0x34>
    n = ip->size - off;
    80004480:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004484:	0a0a8963          	beqz	s5,80004536 <readi+0xe6>
    80004488:	e8ca                	sd	s2,80(sp)
    8000448a:	f062                	sd	s8,32(sp)
    8000448c:	ec66                	sd	s9,24(sp)
    8000448e:	e86a                	sd	s10,16(sp)
    80004490:	e46e                	sd	s11,8(sp)
    80004492:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004494:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004498:	5c7d                	li	s8,-1
    8000449a:	a82d                	j	800044d4 <readi+0x84>
    8000449c:	020d1d93          	sll	s11,s10,0x20
    800044a0:	020ddd93          	srl	s11,s11,0x20
    800044a4:	05890613          	add	a2,s2,88
    800044a8:	86ee                	mv	a3,s11
    800044aa:	963a                	add	a2,a2,a4
    800044ac:	85d2                	mv	a1,s4
    800044ae:	855e                	mv	a0,s7
    800044b0:	ffffe097          	auipc	ra,0xffffe
    800044b4:	580080e7          	jalr	1408(ra) # 80002a30 <either_copyout>
    800044b8:	05850d63          	beq	a0,s8,80004512 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800044bc:	854a                	mv	a0,s2
    800044be:	fffff097          	auipc	ra,0xfffff
    800044c2:	5d6080e7          	jalr	1494(ra) # 80003a94 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800044c6:	013d09bb          	addw	s3,s10,s3
    800044ca:	009d04bb          	addw	s1,s10,s1
    800044ce:	9a6e                	add	s4,s4,s11
    800044d0:	0559fd63          	bgeu	s3,s5,8000452a <readi+0xda>
    uint addr = bmap(ip, off/BSIZE);
    800044d4:	00a4d59b          	srlw	a1,s1,0xa
    800044d8:	855a                	mv	a0,s6
    800044da:	00000097          	auipc	ra,0x0
    800044de:	88e080e7          	jalr	-1906(ra) # 80003d68 <bmap>
    800044e2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800044e6:	c9b1                	beqz	a1,8000453a <readi+0xea>
    bp = bread(ip->dev, addr);
    800044e8:	000b2503          	lw	a0,0(s6)
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	478080e7          	jalr	1144(ra) # 80003964 <bread>
    800044f4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800044f6:	3ff4f713          	and	a4,s1,1023
    800044fa:	40ec87bb          	subw	a5,s9,a4
    800044fe:	413a86bb          	subw	a3,s5,s3
    80004502:	8d3e                	mv	s10,a5
    80004504:	2781                	sext.w	a5,a5
    80004506:	0006861b          	sext.w	a2,a3
    8000450a:	f8f679e3          	bgeu	a2,a5,8000449c <readi+0x4c>
    8000450e:	8d36                	mv	s10,a3
    80004510:	b771                	j	8000449c <readi+0x4c>
      brelse(bp);
    80004512:	854a                	mv	a0,s2
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	580080e7          	jalr	1408(ra) # 80003a94 <brelse>
      tot = -1;
    8000451c:	59fd                	li	s3,-1
      break;
    8000451e:	6946                	ld	s2,80(sp)
    80004520:	7c02                	ld	s8,32(sp)
    80004522:	6ce2                	ld	s9,24(sp)
    80004524:	6d42                	ld	s10,16(sp)
    80004526:	6da2                	ld	s11,8(sp)
    80004528:	a831                	j	80004544 <readi+0xf4>
    8000452a:	6946                	ld	s2,80(sp)
    8000452c:	7c02                	ld	s8,32(sp)
    8000452e:	6ce2                	ld	s9,24(sp)
    80004530:	6d42                	ld	s10,16(sp)
    80004532:	6da2                	ld	s11,8(sp)
    80004534:	a801                	j	80004544 <readi+0xf4>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004536:	89d6                	mv	s3,s5
    80004538:	a031                	j	80004544 <readi+0xf4>
    8000453a:	6946                	ld	s2,80(sp)
    8000453c:	7c02                	ld	s8,32(sp)
    8000453e:	6ce2                	ld	s9,24(sp)
    80004540:	6d42                	ld	s10,16(sp)
    80004542:	6da2                	ld	s11,8(sp)
  }
  return tot;
    80004544:	0009851b          	sext.w	a0,s3
    80004548:	69a6                	ld	s3,72(sp)
}
    8000454a:	70a6                	ld	ra,104(sp)
    8000454c:	7406                	ld	s0,96(sp)
    8000454e:	64e6                	ld	s1,88(sp)
    80004550:	6a06                	ld	s4,64(sp)
    80004552:	7ae2                	ld	s5,56(sp)
    80004554:	7b42                	ld	s6,48(sp)
    80004556:	7ba2                	ld	s7,40(sp)
    80004558:	6165                	add	sp,sp,112
    8000455a:	8082                	ret
    return 0;
    8000455c:	4501                	li	a0,0
}
    8000455e:	8082                	ret

0000000080004560 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004560:	457c                	lw	a5,76(a0)
    80004562:	10d7ee63          	bltu	a5,a3,8000467e <writei+0x11e>
{
    80004566:	7159                	add	sp,sp,-112
    80004568:	f486                	sd	ra,104(sp)
    8000456a:	f0a2                	sd	s0,96(sp)
    8000456c:	e8ca                	sd	s2,80(sp)
    8000456e:	e0d2                	sd	s4,64(sp)
    80004570:	fc56                	sd	s5,56(sp)
    80004572:	f85a                	sd	s6,48(sp)
    80004574:	f45e                	sd	s7,40(sp)
    80004576:	1880                	add	s0,sp,112
    80004578:	8aaa                	mv	s5,a0
    8000457a:	8bae                	mv	s7,a1
    8000457c:	8a32                	mv	s4,a2
    8000457e:	8936                	mv	s2,a3
    80004580:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004582:	00e687bb          	addw	a5,a3,a4
    80004586:	0ed7ee63          	bltu	a5,a3,80004682 <writei+0x122>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000458a:	00043737          	lui	a4,0x43
    8000458e:	0ef76c63          	bltu	a4,a5,80004686 <writei+0x126>
    80004592:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004594:	0c0b0d63          	beqz	s6,8000466e <writei+0x10e>
    80004598:	eca6                	sd	s1,88(sp)
    8000459a:	f062                	sd	s8,32(sp)
    8000459c:	ec66                	sd	s9,24(sp)
    8000459e:	e86a                	sd	s10,16(sp)
    800045a0:	e46e                	sd	s11,8(sp)
    800045a2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800045a4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800045a8:	5c7d                	li	s8,-1
    800045aa:	a091                	j	800045ee <writei+0x8e>
    800045ac:	020d1d93          	sll	s11,s10,0x20
    800045b0:	020ddd93          	srl	s11,s11,0x20
    800045b4:	05848513          	add	a0,s1,88
    800045b8:	86ee                	mv	a3,s11
    800045ba:	8652                	mv	a2,s4
    800045bc:	85de                	mv	a1,s7
    800045be:	953a                	add	a0,a0,a4
    800045c0:	ffffe097          	auipc	ra,0xffffe
    800045c4:	4c6080e7          	jalr	1222(ra) # 80002a86 <either_copyin>
    800045c8:	07850263          	beq	a0,s8,8000462c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800045cc:	8526                	mv	a0,s1
    800045ce:	00000097          	auipc	ra,0x0
    800045d2:	770080e7          	jalr	1904(ra) # 80004d3e <log_write>
    brelse(bp);
    800045d6:	8526                	mv	a0,s1
    800045d8:	fffff097          	auipc	ra,0xfffff
    800045dc:	4bc080e7          	jalr	1212(ra) # 80003a94 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045e0:	013d09bb          	addw	s3,s10,s3
    800045e4:	012d093b          	addw	s2,s10,s2
    800045e8:	9a6e                	add	s4,s4,s11
    800045ea:	0569f663          	bgeu	s3,s6,80004636 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800045ee:	00a9559b          	srlw	a1,s2,0xa
    800045f2:	8556                	mv	a0,s5
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	774080e7          	jalr	1908(ra) # 80003d68 <bmap>
    800045fc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004600:	c99d                	beqz	a1,80004636 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004602:	000aa503          	lw	a0,0(s5)
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	35e080e7          	jalr	862(ra) # 80003964 <bread>
    8000460e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004610:	3ff97713          	and	a4,s2,1023
    80004614:	40ec87bb          	subw	a5,s9,a4
    80004618:	413b06bb          	subw	a3,s6,s3
    8000461c:	8d3e                	mv	s10,a5
    8000461e:	2781                	sext.w	a5,a5
    80004620:	0006861b          	sext.w	a2,a3
    80004624:	f8f674e3          	bgeu	a2,a5,800045ac <writei+0x4c>
    80004628:	8d36                	mv	s10,a3
    8000462a:	b749                	j	800045ac <writei+0x4c>
      brelse(bp);
    8000462c:	8526                	mv	a0,s1
    8000462e:	fffff097          	auipc	ra,0xfffff
    80004632:	466080e7          	jalr	1126(ra) # 80003a94 <brelse>
  }

  if(off > ip->size)
    80004636:	04caa783          	lw	a5,76(s5)
    8000463a:	0327fc63          	bgeu	a5,s2,80004672 <writei+0x112>
    ip->size = off;
    8000463e:	052aa623          	sw	s2,76(s5)
    80004642:	64e6                	ld	s1,88(sp)
    80004644:	7c02                	ld	s8,32(sp)
    80004646:	6ce2                	ld	s9,24(sp)
    80004648:	6d42                	ld	s10,16(sp)
    8000464a:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000464c:	8556                	mv	a0,s5
    8000464e:	00000097          	auipc	ra,0x0
    80004652:	a7e080e7          	jalr	-1410(ra) # 800040cc <iupdate>

  return tot;
    80004656:	0009851b          	sext.w	a0,s3
    8000465a:	69a6                	ld	s3,72(sp)
}
    8000465c:	70a6                	ld	ra,104(sp)
    8000465e:	7406                	ld	s0,96(sp)
    80004660:	6946                	ld	s2,80(sp)
    80004662:	6a06                	ld	s4,64(sp)
    80004664:	7ae2                	ld	s5,56(sp)
    80004666:	7b42                	ld	s6,48(sp)
    80004668:	7ba2                	ld	s7,40(sp)
    8000466a:	6165                	add	sp,sp,112
    8000466c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000466e:	89da                	mv	s3,s6
    80004670:	bff1                	j	8000464c <writei+0xec>
    80004672:	64e6                	ld	s1,88(sp)
    80004674:	7c02                	ld	s8,32(sp)
    80004676:	6ce2                	ld	s9,24(sp)
    80004678:	6d42                	ld	s10,16(sp)
    8000467a:	6da2                	ld	s11,8(sp)
    8000467c:	bfc1                	j	8000464c <writei+0xec>
    return -1;
    8000467e:	557d                	li	a0,-1
}
    80004680:	8082                	ret
    return -1;
    80004682:	557d                	li	a0,-1
    80004684:	bfe1                	j	8000465c <writei+0xfc>
    return -1;
    80004686:	557d                	li	a0,-1
    80004688:	bfd1                	j	8000465c <writei+0xfc>

000000008000468a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000468a:	1141                	add	sp,sp,-16
    8000468c:	e406                	sd	ra,8(sp)
    8000468e:	e022                	sd	s0,0(sp)
    80004690:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004692:	4639                	li	a2,14
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	770080e7          	jalr	1904(ra) # 80000e04 <strncmp>
}
    8000469c:	60a2                	ld	ra,8(sp)
    8000469e:	6402                	ld	s0,0(sp)
    800046a0:	0141                	add	sp,sp,16
    800046a2:	8082                	ret

00000000800046a4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800046a4:	7139                	add	sp,sp,-64
    800046a6:	fc06                	sd	ra,56(sp)
    800046a8:	f822                	sd	s0,48(sp)
    800046aa:	f426                	sd	s1,40(sp)
    800046ac:	f04a                	sd	s2,32(sp)
    800046ae:	ec4e                	sd	s3,24(sp)
    800046b0:	e852                	sd	s4,16(sp)
    800046b2:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800046b4:	04451703          	lh	a4,68(a0)
    800046b8:	4785                	li	a5,1
    800046ba:	00f71a63          	bne	a4,a5,800046ce <dirlookup+0x2a>
    800046be:	892a                	mv	s2,a0
    800046c0:	89ae                	mv	s3,a1
    800046c2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800046c4:	457c                	lw	a5,76(a0)
    800046c6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800046c8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046ca:	e79d                	bnez	a5,800046f8 <dirlookup+0x54>
    800046cc:	a8a5                	j	80004744 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800046ce:	00005517          	auipc	a0,0x5
    800046d2:	fb250513          	add	a0,a0,-78 # 80009680 <etext+0x680>
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	e8a080e7          	jalr	-374(ra) # 80000560 <panic>
      panic("dirlookup read");
    800046de:	00005517          	auipc	a0,0x5
    800046e2:	fba50513          	add	a0,a0,-70 # 80009698 <etext+0x698>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	e7a080e7          	jalr	-390(ra) # 80000560 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046ee:	24c1                	addw	s1,s1,16
    800046f0:	04c92783          	lw	a5,76(s2)
    800046f4:	04f4f763          	bgeu	s1,a5,80004742 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046f8:	4741                	li	a4,16
    800046fa:	86a6                	mv	a3,s1
    800046fc:	fc040613          	add	a2,s0,-64
    80004700:	4581                	li	a1,0
    80004702:	854a                	mv	a0,s2
    80004704:	00000097          	auipc	ra,0x0
    80004708:	d4c080e7          	jalr	-692(ra) # 80004450 <readi>
    8000470c:	47c1                	li	a5,16
    8000470e:	fcf518e3          	bne	a0,a5,800046de <dirlookup+0x3a>
    if(de.inum == 0)
    80004712:	fc045783          	lhu	a5,-64(s0)
    80004716:	dfe1                	beqz	a5,800046ee <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004718:	fc240593          	add	a1,s0,-62
    8000471c:	854e                	mv	a0,s3
    8000471e:	00000097          	auipc	ra,0x0
    80004722:	f6c080e7          	jalr	-148(ra) # 8000468a <namecmp>
    80004726:	f561                	bnez	a0,800046ee <dirlookup+0x4a>
      if(poff)
    80004728:	000a0463          	beqz	s4,80004730 <dirlookup+0x8c>
        *poff = off;
    8000472c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004730:	fc045583          	lhu	a1,-64(s0)
    80004734:	00092503          	lw	a0,0(s2)
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	720080e7          	jalr	1824(ra) # 80003e58 <iget>
    80004740:	a011                	j	80004744 <dirlookup+0xa0>
  return 0;
    80004742:	4501                	li	a0,0
}
    80004744:	70e2                	ld	ra,56(sp)
    80004746:	7442                	ld	s0,48(sp)
    80004748:	74a2                	ld	s1,40(sp)
    8000474a:	7902                	ld	s2,32(sp)
    8000474c:	69e2                	ld	s3,24(sp)
    8000474e:	6a42                	ld	s4,16(sp)
    80004750:	6121                	add	sp,sp,64
    80004752:	8082                	ret

0000000080004754 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004754:	711d                	add	sp,sp,-96
    80004756:	ec86                	sd	ra,88(sp)
    80004758:	e8a2                	sd	s0,80(sp)
    8000475a:	e4a6                	sd	s1,72(sp)
    8000475c:	e0ca                	sd	s2,64(sp)
    8000475e:	fc4e                	sd	s3,56(sp)
    80004760:	f852                	sd	s4,48(sp)
    80004762:	f456                	sd	s5,40(sp)
    80004764:	f05a                	sd	s6,32(sp)
    80004766:	ec5e                	sd	s7,24(sp)
    80004768:	e862                	sd	s8,16(sp)
    8000476a:	e466                	sd	s9,8(sp)
    8000476c:	1080                	add	s0,sp,96
    8000476e:	84aa                	mv	s1,a0
    80004770:	8b2e                	mv	s6,a1
    80004772:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004774:	00054703          	lbu	a4,0(a0)
    80004778:	02f00793          	li	a5,47
    8000477c:	02f70263          	beq	a4,a5,800047a0 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004780:	ffffd097          	auipc	ra,0xffffd
    80004784:	40a080e7          	jalr	1034(ra) # 80001b8a <myproc>
    80004788:	15053503          	ld	a0,336(a0)
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	9ce080e7          	jalr	-1586(ra) # 8000415a <idup>
    80004794:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004796:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000479a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000479c:	4b85                	li	s7,1
    8000479e:	a875                	j	8000485a <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800047a0:	4585                	li	a1,1
    800047a2:	4505                	li	a0,1
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	6b4080e7          	jalr	1716(ra) # 80003e58 <iget>
    800047ac:	8a2a                	mv	s4,a0
    800047ae:	b7e5                	j	80004796 <namex+0x42>
      iunlockput(ip);
    800047b0:	8552                	mv	a0,s4
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	c4c080e7          	jalr	-948(ra) # 800043fe <iunlockput>
      return 0;
    800047ba:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800047bc:	8552                	mv	a0,s4
    800047be:	60e6                	ld	ra,88(sp)
    800047c0:	6446                	ld	s0,80(sp)
    800047c2:	64a6                	ld	s1,72(sp)
    800047c4:	6906                	ld	s2,64(sp)
    800047c6:	79e2                	ld	s3,56(sp)
    800047c8:	7a42                	ld	s4,48(sp)
    800047ca:	7aa2                	ld	s5,40(sp)
    800047cc:	7b02                	ld	s6,32(sp)
    800047ce:	6be2                	ld	s7,24(sp)
    800047d0:	6c42                	ld	s8,16(sp)
    800047d2:	6ca2                	ld	s9,8(sp)
    800047d4:	6125                	add	sp,sp,96
    800047d6:	8082                	ret
      iunlock(ip);
    800047d8:	8552                	mv	a0,s4
    800047da:	00000097          	auipc	ra,0x0
    800047de:	a84080e7          	jalr	-1404(ra) # 8000425e <iunlock>
      return ip;
    800047e2:	bfe9                	j	800047bc <namex+0x68>
      iunlockput(ip);
    800047e4:	8552                	mv	a0,s4
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	c18080e7          	jalr	-1000(ra) # 800043fe <iunlockput>
      return 0;
    800047ee:	8a4e                	mv	s4,s3
    800047f0:	b7f1                	j	800047bc <namex+0x68>
  len = path - s;
    800047f2:	40998633          	sub	a2,s3,s1
    800047f6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800047fa:	099c5863          	bge	s8,s9,8000488a <namex+0x136>
    memmove(name, s, DIRSIZ);
    800047fe:	4639                	li	a2,14
    80004800:	85a6                	mv	a1,s1
    80004802:	8556                	mv	a0,s5
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	58c080e7          	jalr	1420(ra) # 80000d90 <memmove>
    8000480c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000480e:	0004c783          	lbu	a5,0(s1)
    80004812:	01279763          	bne	a5,s2,80004820 <namex+0xcc>
    path++;
    80004816:	0485                	add	s1,s1,1
  while(*path == '/')
    80004818:	0004c783          	lbu	a5,0(s1)
    8000481c:	ff278de3          	beq	a5,s2,80004816 <namex+0xc2>
    ilock(ip);
    80004820:	8552                	mv	a0,s4
    80004822:	00000097          	auipc	ra,0x0
    80004826:	976080e7          	jalr	-1674(ra) # 80004198 <ilock>
    if(ip->type != T_DIR){
    8000482a:	044a1783          	lh	a5,68(s4)
    8000482e:	f97791e3          	bne	a5,s7,800047b0 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004832:	000b0563          	beqz	s6,8000483c <namex+0xe8>
    80004836:	0004c783          	lbu	a5,0(s1)
    8000483a:	dfd9                	beqz	a5,800047d8 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000483c:	4601                	li	a2,0
    8000483e:	85d6                	mv	a1,s5
    80004840:	8552                	mv	a0,s4
    80004842:	00000097          	auipc	ra,0x0
    80004846:	e62080e7          	jalr	-414(ra) # 800046a4 <dirlookup>
    8000484a:	89aa                	mv	s3,a0
    8000484c:	dd41                	beqz	a0,800047e4 <namex+0x90>
    iunlockput(ip);
    8000484e:	8552                	mv	a0,s4
    80004850:	00000097          	auipc	ra,0x0
    80004854:	bae080e7          	jalr	-1106(ra) # 800043fe <iunlockput>
    ip = next;
    80004858:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000485a:	0004c783          	lbu	a5,0(s1)
    8000485e:	01279763          	bne	a5,s2,8000486c <namex+0x118>
    path++;
    80004862:	0485                	add	s1,s1,1
  while(*path == '/')
    80004864:	0004c783          	lbu	a5,0(s1)
    80004868:	ff278de3          	beq	a5,s2,80004862 <namex+0x10e>
  if(*path == 0)
    8000486c:	cb9d                	beqz	a5,800048a2 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000486e:	0004c783          	lbu	a5,0(s1)
    80004872:	89a6                	mv	s3,s1
  len = path - s;
    80004874:	4c81                	li	s9,0
    80004876:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004878:	01278963          	beq	a5,s2,8000488a <namex+0x136>
    8000487c:	dbbd                	beqz	a5,800047f2 <namex+0x9e>
    path++;
    8000487e:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    80004880:	0009c783          	lbu	a5,0(s3)
    80004884:	ff279ce3          	bne	a5,s2,8000487c <namex+0x128>
    80004888:	b7ad                	j	800047f2 <namex+0x9e>
    memmove(name, s, len);
    8000488a:	2601                	sext.w	a2,a2
    8000488c:	85a6                	mv	a1,s1
    8000488e:	8556                	mv	a0,s5
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	500080e7          	jalr	1280(ra) # 80000d90 <memmove>
    name[len] = 0;
    80004898:	9cd6                	add	s9,s9,s5
    8000489a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000489e:	84ce                	mv	s1,s3
    800048a0:	b7bd                	j	8000480e <namex+0xba>
  if(nameiparent){
    800048a2:	f00b0de3          	beqz	s6,800047bc <namex+0x68>
    iput(ip);
    800048a6:	8552                	mv	a0,s4
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	aae080e7          	jalr	-1362(ra) # 80004356 <iput>
    return 0;
    800048b0:	4a01                	li	s4,0
    800048b2:	b729                	j	800047bc <namex+0x68>

00000000800048b4 <dirlink>:
{
    800048b4:	7139                	add	sp,sp,-64
    800048b6:	fc06                	sd	ra,56(sp)
    800048b8:	f822                	sd	s0,48(sp)
    800048ba:	f04a                	sd	s2,32(sp)
    800048bc:	ec4e                	sd	s3,24(sp)
    800048be:	e852                	sd	s4,16(sp)
    800048c0:	0080                	add	s0,sp,64
    800048c2:	892a                	mv	s2,a0
    800048c4:	8a2e                	mv	s4,a1
    800048c6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800048c8:	4601                	li	a2,0
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	dda080e7          	jalr	-550(ra) # 800046a4 <dirlookup>
    800048d2:	ed25                	bnez	a0,8000494a <dirlink+0x96>
    800048d4:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048d6:	04c92483          	lw	s1,76(s2)
    800048da:	c49d                	beqz	s1,80004908 <dirlink+0x54>
    800048dc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048de:	4741                	li	a4,16
    800048e0:	86a6                	mv	a3,s1
    800048e2:	fc040613          	add	a2,s0,-64
    800048e6:	4581                	li	a1,0
    800048e8:	854a                	mv	a0,s2
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	b66080e7          	jalr	-1178(ra) # 80004450 <readi>
    800048f2:	47c1                	li	a5,16
    800048f4:	06f51163          	bne	a0,a5,80004956 <dirlink+0xa2>
    if(de.inum == 0)
    800048f8:	fc045783          	lhu	a5,-64(s0)
    800048fc:	c791                	beqz	a5,80004908 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048fe:	24c1                	addw	s1,s1,16
    80004900:	04c92783          	lw	a5,76(s2)
    80004904:	fcf4ede3          	bltu	s1,a5,800048de <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004908:	4639                	li	a2,14
    8000490a:	85d2                	mv	a1,s4
    8000490c:	fc240513          	add	a0,s0,-62
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	52a080e7          	jalr	1322(ra) # 80000e3a <strncpy>
  de.inum = inum;
    80004918:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000491c:	4741                	li	a4,16
    8000491e:	86a6                	mv	a3,s1
    80004920:	fc040613          	add	a2,s0,-64
    80004924:	4581                	li	a1,0
    80004926:	854a                	mv	a0,s2
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	c38080e7          	jalr	-968(ra) # 80004560 <writei>
    80004930:	1541                	add	a0,a0,-16
    80004932:	00a03533          	snez	a0,a0
    80004936:	40a00533          	neg	a0,a0
    8000493a:	74a2                	ld	s1,40(sp)
}
    8000493c:	70e2                	ld	ra,56(sp)
    8000493e:	7442                	ld	s0,48(sp)
    80004940:	7902                	ld	s2,32(sp)
    80004942:	69e2                	ld	s3,24(sp)
    80004944:	6a42                	ld	s4,16(sp)
    80004946:	6121                	add	sp,sp,64
    80004948:	8082                	ret
    iput(ip);
    8000494a:	00000097          	auipc	ra,0x0
    8000494e:	a0c080e7          	jalr	-1524(ra) # 80004356 <iput>
    return -1;
    80004952:	557d                	li	a0,-1
    80004954:	b7e5                	j	8000493c <dirlink+0x88>
      panic("dirlink read");
    80004956:	00005517          	auipc	a0,0x5
    8000495a:	d5250513          	add	a0,a0,-686 # 800096a8 <etext+0x6a8>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	c02080e7          	jalr	-1022(ra) # 80000560 <panic>

0000000080004966 <namei>:

struct inode*
namei(char *path)
{
    80004966:	1101                	add	sp,sp,-32
    80004968:	ec06                	sd	ra,24(sp)
    8000496a:	e822                	sd	s0,16(sp)
    8000496c:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000496e:	fe040613          	add	a2,s0,-32
    80004972:	4581                	li	a1,0
    80004974:	00000097          	auipc	ra,0x0
    80004978:	de0080e7          	jalr	-544(ra) # 80004754 <namex>
}
    8000497c:	60e2                	ld	ra,24(sp)
    8000497e:	6442                	ld	s0,16(sp)
    80004980:	6105                	add	sp,sp,32
    80004982:	8082                	ret

0000000080004984 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004984:	1141                	add	sp,sp,-16
    80004986:	e406                	sd	ra,8(sp)
    80004988:	e022                	sd	s0,0(sp)
    8000498a:	0800                	add	s0,sp,16
    8000498c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000498e:	4585                	li	a1,1
    80004990:	00000097          	auipc	ra,0x0
    80004994:	dc4080e7          	jalr	-572(ra) # 80004754 <namex>
}
    80004998:	60a2                	ld	ra,8(sp)
    8000499a:	6402                	ld	s0,0(sp)
    8000499c:	0141                	add	sp,sp,16
    8000499e:	8082                	ret

00000000800049a0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800049a0:	1101                	add	sp,sp,-32
    800049a2:	ec06                	sd	ra,24(sp)
    800049a4:	e822                	sd	s0,16(sp)
    800049a6:	e426                	sd	s1,8(sp)
    800049a8:	e04a                	sd	s2,0(sp)
    800049aa:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800049ac:	0001f917          	auipc	s2,0x1f
    800049b0:	a9490913          	add	s2,s2,-1388 # 80023440 <log>
    800049b4:	01892583          	lw	a1,24(s2)
    800049b8:	02892503          	lw	a0,40(s2)
    800049bc:	fffff097          	auipc	ra,0xfffff
    800049c0:	fa8080e7          	jalr	-88(ra) # 80003964 <bread>
    800049c4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800049c6:	02c92603          	lw	a2,44(s2)
    800049ca:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800049cc:	00c05f63          	blez	a2,800049ea <write_head+0x4a>
    800049d0:	0001f717          	auipc	a4,0x1f
    800049d4:	aa070713          	add	a4,a4,-1376 # 80023470 <log+0x30>
    800049d8:	87aa                	mv	a5,a0
    800049da:	060a                	sll	a2,a2,0x2
    800049dc:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800049de:	4314                	lw	a3,0(a4)
    800049e0:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800049e2:	0711                	add	a4,a4,4
    800049e4:	0791                	add	a5,a5,4
    800049e6:	fec79ce3          	bne	a5,a2,800049de <write_head+0x3e>
  }
  bwrite(buf);
    800049ea:	8526                	mv	a0,s1
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	06a080e7          	jalr	106(ra) # 80003a56 <bwrite>
  brelse(buf);
    800049f4:	8526                	mv	a0,s1
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	09e080e7          	jalr	158(ra) # 80003a94 <brelse>
}
    800049fe:	60e2                	ld	ra,24(sp)
    80004a00:	6442                	ld	s0,16(sp)
    80004a02:	64a2                	ld	s1,8(sp)
    80004a04:	6902                	ld	s2,0(sp)
    80004a06:	6105                	add	sp,sp,32
    80004a08:	8082                	ret

0000000080004a0a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a0a:	0001f797          	auipc	a5,0x1f
    80004a0e:	a627a783          	lw	a5,-1438(a5) # 8002346c <log+0x2c>
    80004a12:	0af05d63          	blez	a5,80004acc <install_trans+0xc2>
{
    80004a16:	7139                	add	sp,sp,-64
    80004a18:	fc06                	sd	ra,56(sp)
    80004a1a:	f822                	sd	s0,48(sp)
    80004a1c:	f426                	sd	s1,40(sp)
    80004a1e:	f04a                	sd	s2,32(sp)
    80004a20:	ec4e                	sd	s3,24(sp)
    80004a22:	e852                	sd	s4,16(sp)
    80004a24:	e456                	sd	s5,8(sp)
    80004a26:	e05a                	sd	s6,0(sp)
    80004a28:	0080                	add	s0,sp,64
    80004a2a:	8b2a                	mv	s6,a0
    80004a2c:	0001fa97          	auipc	s5,0x1f
    80004a30:	a44a8a93          	add	s5,s5,-1468 # 80023470 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a34:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a36:	0001f997          	auipc	s3,0x1f
    80004a3a:	a0a98993          	add	s3,s3,-1526 # 80023440 <log>
    80004a3e:	a00d                	j	80004a60 <install_trans+0x56>
    brelse(lbuf);
    80004a40:	854a                	mv	a0,s2
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	052080e7          	jalr	82(ra) # 80003a94 <brelse>
    brelse(dbuf);
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	fffff097          	auipc	ra,0xfffff
    80004a50:	048080e7          	jalr	72(ra) # 80003a94 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a54:	2a05                	addw	s4,s4,1
    80004a56:	0a91                	add	s5,s5,4
    80004a58:	02c9a783          	lw	a5,44(s3)
    80004a5c:	04fa5e63          	bge	s4,a5,80004ab8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a60:	0189a583          	lw	a1,24(s3)
    80004a64:	014585bb          	addw	a1,a1,s4
    80004a68:	2585                	addw	a1,a1,1
    80004a6a:	0289a503          	lw	a0,40(s3)
    80004a6e:	fffff097          	auipc	ra,0xfffff
    80004a72:	ef6080e7          	jalr	-266(ra) # 80003964 <bread>
    80004a76:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004a78:	000aa583          	lw	a1,0(s5)
    80004a7c:	0289a503          	lw	a0,40(s3)
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	ee4080e7          	jalr	-284(ra) # 80003964 <bread>
    80004a88:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004a8a:	40000613          	li	a2,1024
    80004a8e:	05890593          	add	a1,s2,88
    80004a92:	05850513          	add	a0,a0,88
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	2fa080e7          	jalr	762(ra) # 80000d90 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	fb6080e7          	jalr	-74(ra) # 80003a56 <bwrite>
    if(recovering == 0)
    80004aa8:	f80b1ce3          	bnez	s6,80004a40 <install_trans+0x36>
      bunpin(dbuf);
    80004aac:	8526                	mv	a0,s1
    80004aae:	fffff097          	auipc	ra,0xfffff
    80004ab2:	0be080e7          	jalr	190(ra) # 80003b6c <bunpin>
    80004ab6:	b769                	j	80004a40 <install_trans+0x36>
}
    80004ab8:	70e2                	ld	ra,56(sp)
    80004aba:	7442                	ld	s0,48(sp)
    80004abc:	74a2                	ld	s1,40(sp)
    80004abe:	7902                	ld	s2,32(sp)
    80004ac0:	69e2                	ld	s3,24(sp)
    80004ac2:	6a42                	ld	s4,16(sp)
    80004ac4:	6aa2                	ld	s5,8(sp)
    80004ac6:	6b02                	ld	s6,0(sp)
    80004ac8:	6121                	add	sp,sp,64
    80004aca:	8082                	ret
    80004acc:	8082                	ret

0000000080004ace <initlog>:
{
    80004ace:	7179                	add	sp,sp,-48
    80004ad0:	f406                	sd	ra,40(sp)
    80004ad2:	f022                	sd	s0,32(sp)
    80004ad4:	ec26                	sd	s1,24(sp)
    80004ad6:	e84a                	sd	s2,16(sp)
    80004ad8:	e44e                	sd	s3,8(sp)
    80004ada:	1800                	add	s0,sp,48
    80004adc:	892a                	mv	s2,a0
    80004ade:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004ae0:	0001f497          	auipc	s1,0x1f
    80004ae4:	96048493          	add	s1,s1,-1696 # 80023440 <log>
    80004ae8:	00005597          	auipc	a1,0x5
    80004aec:	bd058593          	add	a1,a1,-1072 # 800096b8 <etext+0x6b8>
    80004af0:	8526                	mv	a0,s1
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	0b6080e7          	jalr	182(ra) # 80000ba8 <initlock>
  log.start = sb->logstart;
    80004afa:	0149a583          	lw	a1,20(s3)
    80004afe:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004b00:	0109a783          	lw	a5,16(s3)
    80004b04:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004b06:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004b0a:	854a                	mv	a0,s2
    80004b0c:	fffff097          	auipc	ra,0xfffff
    80004b10:	e58080e7          	jalr	-424(ra) # 80003964 <bread>
  log.lh.n = lh->n;
    80004b14:	4d30                	lw	a2,88(a0)
    80004b16:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004b18:	00c05f63          	blez	a2,80004b36 <initlog+0x68>
    80004b1c:	87aa                	mv	a5,a0
    80004b1e:	0001f717          	auipc	a4,0x1f
    80004b22:	95270713          	add	a4,a4,-1710 # 80023470 <log+0x30>
    80004b26:	060a                	sll	a2,a2,0x2
    80004b28:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004b2a:	4ff4                	lw	a3,92(a5)
    80004b2c:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b2e:	0791                	add	a5,a5,4
    80004b30:	0711                	add	a4,a4,4
    80004b32:	fec79ce3          	bne	a5,a2,80004b2a <initlog+0x5c>
  brelse(buf);
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	f5e080e7          	jalr	-162(ra) # 80003a94 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004b3e:	4505                	li	a0,1
    80004b40:	00000097          	auipc	ra,0x0
    80004b44:	eca080e7          	jalr	-310(ra) # 80004a0a <install_trans>
  log.lh.n = 0;
    80004b48:	0001f797          	auipc	a5,0x1f
    80004b4c:	9207a223          	sw	zero,-1756(a5) # 8002346c <log+0x2c>
  write_head(); // clear the log
    80004b50:	00000097          	auipc	ra,0x0
    80004b54:	e50080e7          	jalr	-432(ra) # 800049a0 <write_head>
}
    80004b58:	70a2                	ld	ra,40(sp)
    80004b5a:	7402                	ld	s0,32(sp)
    80004b5c:	64e2                	ld	s1,24(sp)
    80004b5e:	6942                	ld	s2,16(sp)
    80004b60:	69a2                	ld	s3,8(sp)
    80004b62:	6145                	add	sp,sp,48
    80004b64:	8082                	ret

0000000080004b66 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004b66:	1101                	add	sp,sp,-32
    80004b68:	ec06                	sd	ra,24(sp)
    80004b6a:	e822                	sd	s0,16(sp)
    80004b6c:	e426                	sd	s1,8(sp)
    80004b6e:	e04a                	sd	s2,0(sp)
    80004b70:	1000                	add	s0,sp,32
  acquire(&log.lock);
    80004b72:	0001f517          	auipc	a0,0x1f
    80004b76:	8ce50513          	add	a0,a0,-1842 # 80023440 <log>
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	0be080e7          	jalr	190(ra) # 80000c38 <acquire>
  while(1){
    if(log.committing){
    80004b82:	0001f497          	auipc	s1,0x1f
    80004b86:	8be48493          	add	s1,s1,-1858 # 80023440 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b8a:	4979                	li	s2,30
    80004b8c:	a039                	j	80004b9a <begin_op+0x34>
      sleep(&log, &log.lock);
    80004b8e:	85a6                	mv	a1,s1
    80004b90:	8526                	mv	a0,s1
    80004b92:	ffffe097          	auipc	ra,0xffffe
    80004b96:	93e080e7          	jalr	-1730(ra) # 800024d0 <sleep>
    if(log.committing){
    80004b9a:	50dc                	lw	a5,36(s1)
    80004b9c:	fbed                	bnez	a5,80004b8e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b9e:	5098                	lw	a4,32(s1)
    80004ba0:	2705                	addw	a4,a4,1
    80004ba2:	0027179b          	sllw	a5,a4,0x2
    80004ba6:	9fb9                	addw	a5,a5,a4
    80004ba8:	0017979b          	sllw	a5,a5,0x1
    80004bac:	54d4                	lw	a3,44(s1)
    80004bae:	9fb5                	addw	a5,a5,a3
    80004bb0:	00f95963          	bge	s2,a5,80004bc2 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004bb4:	85a6                	mv	a1,s1
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	ffffe097          	auipc	ra,0xffffe
    80004bbc:	918080e7          	jalr	-1768(ra) # 800024d0 <sleep>
    80004bc0:	bfe9                	j	80004b9a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004bc2:	0001f517          	auipc	a0,0x1f
    80004bc6:	87e50513          	add	a0,a0,-1922 # 80023440 <log>
    80004bca:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	120080e7          	jalr	288(ra) # 80000cec <release>
      break;
    }
  }
}
    80004bd4:	60e2                	ld	ra,24(sp)
    80004bd6:	6442                	ld	s0,16(sp)
    80004bd8:	64a2                	ld	s1,8(sp)
    80004bda:	6902                	ld	s2,0(sp)
    80004bdc:	6105                	add	sp,sp,32
    80004bde:	8082                	ret

0000000080004be0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004be0:	7139                	add	sp,sp,-64
    80004be2:	fc06                	sd	ra,56(sp)
    80004be4:	f822                	sd	s0,48(sp)
    80004be6:	f426                	sd	s1,40(sp)
    80004be8:	f04a                	sd	s2,32(sp)
    80004bea:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004bec:	0001f497          	auipc	s1,0x1f
    80004bf0:	85448493          	add	s1,s1,-1964 # 80023440 <log>
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	042080e7          	jalr	66(ra) # 80000c38 <acquire>
  log.outstanding -= 1;
    80004bfe:	509c                	lw	a5,32(s1)
    80004c00:	37fd                	addw	a5,a5,-1
    80004c02:	0007891b          	sext.w	s2,a5
    80004c06:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004c08:	50dc                	lw	a5,36(s1)
    80004c0a:	e7b9                	bnez	a5,80004c58 <end_op+0x78>
    panic("log.committing");
  if(log.outstanding == 0){
    80004c0c:	06091163          	bnez	s2,80004c6e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004c10:	0001f497          	auipc	s1,0x1f
    80004c14:	83048493          	add	s1,s1,-2000 # 80023440 <log>
    80004c18:	4785                	li	a5,1
    80004c1a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004c1c:	8526                	mv	a0,s1
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	0ce080e7          	jalr	206(ra) # 80000cec <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004c26:	54dc                	lw	a5,44(s1)
    80004c28:	06f04763          	bgtz	a5,80004c96 <end_op+0xb6>
    acquire(&log.lock);
    80004c2c:	0001f497          	auipc	s1,0x1f
    80004c30:	81448493          	add	s1,s1,-2028 # 80023440 <log>
    80004c34:	8526                	mv	a0,s1
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	002080e7          	jalr	2(ra) # 80000c38 <acquire>
    log.committing = 0;
    80004c3e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004c42:	8526                	mv	a0,s1
    80004c44:	ffffe097          	auipc	ra,0xffffe
    80004c48:	a3c080e7          	jalr	-1476(ra) # 80002680 <wakeup>
    release(&log.lock);
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	09e080e7          	jalr	158(ra) # 80000cec <release>
}
    80004c56:	a815                	j	80004c8a <end_op+0xaa>
    80004c58:	ec4e                	sd	s3,24(sp)
    80004c5a:	e852                	sd	s4,16(sp)
    80004c5c:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80004c5e:	00005517          	auipc	a0,0x5
    80004c62:	a6250513          	add	a0,a0,-1438 # 800096c0 <etext+0x6c0>
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	8fa080e7          	jalr	-1798(ra) # 80000560 <panic>
    wakeup(&log);
    80004c6e:	0001e497          	auipc	s1,0x1e
    80004c72:	7d248493          	add	s1,s1,2002 # 80023440 <log>
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffe097          	auipc	ra,0xffffe
    80004c7c:	a08080e7          	jalr	-1528(ra) # 80002680 <wakeup>
  release(&log.lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	06a080e7          	jalr	106(ra) # 80000cec <release>
}
    80004c8a:	70e2                	ld	ra,56(sp)
    80004c8c:	7442                	ld	s0,48(sp)
    80004c8e:	74a2                	ld	s1,40(sp)
    80004c90:	7902                	ld	s2,32(sp)
    80004c92:	6121                	add	sp,sp,64
    80004c94:	8082                	ret
    80004c96:	ec4e                	sd	s3,24(sp)
    80004c98:	e852                	sd	s4,16(sp)
    80004c9a:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c9c:	0001ea97          	auipc	s5,0x1e
    80004ca0:	7d4a8a93          	add	s5,s5,2004 # 80023470 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ca4:	0001ea17          	auipc	s4,0x1e
    80004ca8:	79ca0a13          	add	s4,s4,1948 # 80023440 <log>
    80004cac:	018a2583          	lw	a1,24(s4)
    80004cb0:	012585bb          	addw	a1,a1,s2
    80004cb4:	2585                	addw	a1,a1,1
    80004cb6:	028a2503          	lw	a0,40(s4)
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	caa080e7          	jalr	-854(ra) # 80003964 <bread>
    80004cc2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004cc4:	000aa583          	lw	a1,0(s5)
    80004cc8:	028a2503          	lw	a0,40(s4)
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	c98080e7          	jalr	-872(ra) # 80003964 <bread>
    80004cd4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004cd6:	40000613          	li	a2,1024
    80004cda:	05850593          	add	a1,a0,88
    80004cde:	05848513          	add	a0,s1,88
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	0ae080e7          	jalr	174(ra) # 80000d90 <memmove>
    bwrite(to);  // write the log
    80004cea:	8526                	mv	a0,s1
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	d6a080e7          	jalr	-662(ra) # 80003a56 <bwrite>
    brelse(from);
    80004cf4:	854e                	mv	a0,s3
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	d9e080e7          	jalr	-610(ra) # 80003a94 <brelse>
    brelse(to);
    80004cfe:	8526                	mv	a0,s1
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	d94080e7          	jalr	-620(ra) # 80003a94 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d08:	2905                	addw	s2,s2,1
    80004d0a:	0a91                	add	s5,s5,4
    80004d0c:	02ca2783          	lw	a5,44(s4)
    80004d10:	f8f94ee3          	blt	s2,a5,80004cac <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004d14:	00000097          	auipc	ra,0x0
    80004d18:	c8c080e7          	jalr	-884(ra) # 800049a0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004d1c:	4501                	li	a0,0
    80004d1e:	00000097          	auipc	ra,0x0
    80004d22:	cec080e7          	jalr	-788(ra) # 80004a0a <install_trans>
    log.lh.n = 0;
    80004d26:	0001e797          	auipc	a5,0x1e
    80004d2a:	7407a323          	sw	zero,1862(a5) # 8002346c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004d2e:	00000097          	auipc	ra,0x0
    80004d32:	c72080e7          	jalr	-910(ra) # 800049a0 <write_head>
    80004d36:	69e2                	ld	s3,24(sp)
    80004d38:	6a42                	ld	s4,16(sp)
    80004d3a:	6aa2                	ld	s5,8(sp)
    80004d3c:	bdc5                	j	80004c2c <end_op+0x4c>

0000000080004d3e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004d3e:	1101                	add	sp,sp,-32
    80004d40:	ec06                	sd	ra,24(sp)
    80004d42:	e822                	sd	s0,16(sp)
    80004d44:	e426                	sd	s1,8(sp)
    80004d46:	e04a                	sd	s2,0(sp)
    80004d48:	1000                	add	s0,sp,32
    80004d4a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004d4c:	0001e917          	auipc	s2,0x1e
    80004d50:	6f490913          	add	s2,s2,1780 # 80023440 <log>
    80004d54:	854a                	mv	a0,s2
    80004d56:	ffffc097          	auipc	ra,0xffffc
    80004d5a:	ee2080e7          	jalr	-286(ra) # 80000c38 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004d5e:	02c92603          	lw	a2,44(s2)
    80004d62:	47f5                	li	a5,29
    80004d64:	06c7c563          	blt	a5,a2,80004dce <log_write+0x90>
    80004d68:	0001e797          	auipc	a5,0x1e
    80004d6c:	6f47a783          	lw	a5,1780(a5) # 8002345c <log+0x1c>
    80004d70:	37fd                	addw	a5,a5,-1
    80004d72:	04f65e63          	bge	a2,a5,80004dce <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004d76:	0001e797          	auipc	a5,0x1e
    80004d7a:	6ea7a783          	lw	a5,1770(a5) # 80023460 <log+0x20>
    80004d7e:	06f05063          	blez	a5,80004dde <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004d82:	4781                	li	a5,0
    80004d84:	06c05563          	blez	a2,80004dee <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d88:	44cc                	lw	a1,12(s1)
    80004d8a:	0001e717          	auipc	a4,0x1e
    80004d8e:	6e670713          	add	a4,a4,1766 # 80023470 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004d92:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d94:	4314                	lw	a3,0(a4)
    80004d96:	04b68c63          	beq	a3,a1,80004dee <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004d9a:	2785                	addw	a5,a5,1
    80004d9c:	0711                	add	a4,a4,4
    80004d9e:	fef61be3          	bne	a2,a5,80004d94 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004da2:	0621                	add	a2,a2,8
    80004da4:	060a                	sll	a2,a2,0x2
    80004da6:	0001e797          	auipc	a5,0x1e
    80004daa:	69a78793          	add	a5,a5,1690 # 80023440 <log>
    80004dae:	97b2                	add	a5,a5,a2
    80004db0:	44d8                	lw	a4,12(s1)
    80004db2:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004db4:	8526                	mv	a0,s1
    80004db6:	fffff097          	auipc	ra,0xfffff
    80004dba:	d7a080e7          	jalr	-646(ra) # 80003b30 <bpin>
    log.lh.n++;
    80004dbe:	0001e717          	auipc	a4,0x1e
    80004dc2:	68270713          	add	a4,a4,1666 # 80023440 <log>
    80004dc6:	575c                	lw	a5,44(a4)
    80004dc8:	2785                	addw	a5,a5,1
    80004dca:	d75c                	sw	a5,44(a4)
    80004dcc:	a82d                	j	80004e06 <log_write+0xc8>
    panic("too big a transaction");
    80004dce:	00005517          	auipc	a0,0x5
    80004dd2:	90250513          	add	a0,a0,-1790 # 800096d0 <etext+0x6d0>
    80004dd6:	ffffb097          	auipc	ra,0xffffb
    80004dda:	78a080e7          	jalr	1930(ra) # 80000560 <panic>
    panic("log_write outside of trans");
    80004dde:	00005517          	auipc	a0,0x5
    80004de2:	90a50513          	add	a0,a0,-1782 # 800096e8 <etext+0x6e8>
    80004de6:	ffffb097          	auipc	ra,0xffffb
    80004dea:	77a080e7          	jalr	1914(ra) # 80000560 <panic>
  log.lh.block[i] = b->blockno;
    80004dee:	00878693          	add	a3,a5,8
    80004df2:	068a                	sll	a3,a3,0x2
    80004df4:	0001e717          	auipc	a4,0x1e
    80004df8:	64c70713          	add	a4,a4,1612 # 80023440 <log>
    80004dfc:	9736                	add	a4,a4,a3
    80004dfe:	44d4                	lw	a3,12(s1)
    80004e00:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004e02:	faf609e3          	beq	a2,a5,80004db4 <log_write+0x76>
  }
  release(&log.lock);
    80004e06:	0001e517          	auipc	a0,0x1e
    80004e0a:	63a50513          	add	a0,a0,1594 # 80023440 <log>
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	ede080e7          	jalr	-290(ra) # 80000cec <release>
}
    80004e16:	60e2                	ld	ra,24(sp)
    80004e18:	6442                	ld	s0,16(sp)
    80004e1a:	64a2                	ld	s1,8(sp)
    80004e1c:	6902                	ld	s2,0(sp)
    80004e1e:	6105                	add	sp,sp,32
    80004e20:	8082                	ret

0000000080004e22 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004e22:	1101                	add	sp,sp,-32
    80004e24:	ec06                	sd	ra,24(sp)
    80004e26:	e822                	sd	s0,16(sp)
    80004e28:	e426                	sd	s1,8(sp)
    80004e2a:	e04a                	sd	s2,0(sp)
    80004e2c:	1000                	add	s0,sp,32
    80004e2e:	84aa                	mv	s1,a0
    80004e30:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004e32:	00005597          	auipc	a1,0x5
    80004e36:	8d658593          	add	a1,a1,-1834 # 80009708 <etext+0x708>
    80004e3a:	0521                	add	a0,a0,8
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	d6c080e7          	jalr	-660(ra) # 80000ba8 <initlock>
  lk->name = name;
    80004e44:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004e48:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e4c:	0204a423          	sw	zero,40(s1)
}
    80004e50:	60e2                	ld	ra,24(sp)
    80004e52:	6442                	ld	s0,16(sp)
    80004e54:	64a2                	ld	s1,8(sp)
    80004e56:	6902                	ld	s2,0(sp)
    80004e58:	6105                	add	sp,sp,32
    80004e5a:	8082                	ret

0000000080004e5c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004e5c:	1101                	add	sp,sp,-32
    80004e5e:	ec06                	sd	ra,24(sp)
    80004e60:	e822                	sd	s0,16(sp)
    80004e62:	e426                	sd	s1,8(sp)
    80004e64:	e04a                	sd	s2,0(sp)
    80004e66:	1000                	add	s0,sp,32
    80004e68:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e6a:	00850913          	add	s2,a0,8
    80004e6e:	854a                	mv	a0,s2
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	dc8080e7          	jalr	-568(ra) # 80000c38 <acquire>
  while (lk->locked) {
    80004e78:	409c                	lw	a5,0(s1)
    80004e7a:	cb89                	beqz	a5,80004e8c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004e7c:	85ca                	mv	a1,s2
    80004e7e:	8526                	mv	a0,s1
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	650080e7          	jalr	1616(ra) # 800024d0 <sleep>
  while (lk->locked) {
    80004e88:	409c                	lw	a5,0(s1)
    80004e8a:	fbed                	bnez	a5,80004e7c <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004e8c:	4785                	li	a5,1
    80004e8e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004e90:	ffffd097          	auipc	ra,0xffffd
    80004e94:	cfa080e7          	jalr	-774(ra) # 80001b8a <myproc>
    80004e98:	591c                	lw	a5,48(a0)
    80004e9a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004e9c:	854a                	mv	a0,s2
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	e4e080e7          	jalr	-434(ra) # 80000cec <release>
}
    80004ea6:	60e2                	ld	ra,24(sp)
    80004ea8:	6442                	ld	s0,16(sp)
    80004eaa:	64a2                	ld	s1,8(sp)
    80004eac:	6902                	ld	s2,0(sp)
    80004eae:	6105                	add	sp,sp,32
    80004eb0:	8082                	ret

0000000080004eb2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004eb2:	1101                	add	sp,sp,-32
    80004eb4:	ec06                	sd	ra,24(sp)
    80004eb6:	e822                	sd	s0,16(sp)
    80004eb8:	e426                	sd	s1,8(sp)
    80004eba:	e04a                	sd	s2,0(sp)
    80004ebc:	1000                	add	s0,sp,32
    80004ebe:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ec0:	00850913          	add	s2,a0,8
    80004ec4:	854a                	mv	a0,s2
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	d72080e7          	jalr	-654(ra) # 80000c38 <acquire>
  lk->locked = 0;
    80004ece:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ed2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	ffffd097          	auipc	ra,0xffffd
    80004edc:	7a8080e7          	jalr	1960(ra) # 80002680 <wakeup>
  release(&lk->lk);
    80004ee0:	854a                	mv	a0,s2
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	e0a080e7          	jalr	-502(ra) # 80000cec <release>
}
    80004eea:	60e2                	ld	ra,24(sp)
    80004eec:	6442                	ld	s0,16(sp)
    80004eee:	64a2                	ld	s1,8(sp)
    80004ef0:	6902                	ld	s2,0(sp)
    80004ef2:	6105                	add	sp,sp,32
    80004ef4:	8082                	ret

0000000080004ef6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ef6:	7179                	add	sp,sp,-48
    80004ef8:	f406                	sd	ra,40(sp)
    80004efa:	f022                	sd	s0,32(sp)
    80004efc:	ec26                	sd	s1,24(sp)
    80004efe:	e84a                	sd	s2,16(sp)
    80004f00:	1800                	add	s0,sp,48
    80004f02:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004f04:	00850913          	add	s2,a0,8
    80004f08:	854a                	mv	a0,s2
    80004f0a:	ffffc097          	auipc	ra,0xffffc
    80004f0e:	d2e080e7          	jalr	-722(ra) # 80000c38 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f12:	409c                	lw	a5,0(s1)
    80004f14:	ef91                	bnez	a5,80004f30 <holdingsleep+0x3a>
    80004f16:	4481                	li	s1,0
  release(&lk->lk);
    80004f18:	854a                	mv	a0,s2
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	dd2080e7          	jalr	-558(ra) # 80000cec <release>
  return r;
}
    80004f22:	8526                	mv	a0,s1
    80004f24:	70a2                	ld	ra,40(sp)
    80004f26:	7402                	ld	s0,32(sp)
    80004f28:	64e2                	ld	s1,24(sp)
    80004f2a:	6942                	ld	s2,16(sp)
    80004f2c:	6145                	add	sp,sp,48
    80004f2e:	8082                	ret
    80004f30:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f32:	0284a983          	lw	s3,40(s1)
    80004f36:	ffffd097          	auipc	ra,0xffffd
    80004f3a:	c54080e7          	jalr	-940(ra) # 80001b8a <myproc>
    80004f3e:	5904                	lw	s1,48(a0)
    80004f40:	413484b3          	sub	s1,s1,s3
    80004f44:	0014b493          	seqz	s1,s1
    80004f48:	69a2                	ld	s3,8(sp)
    80004f4a:	b7f9                	j	80004f18 <holdingsleep+0x22>

0000000080004f4c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004f4c:	1141                	add	sp,sp,-16
    80004f4e:	e406                	sd	ra,8(sp)
    80004f50:	e022                	sd	s0,0(sp)
    80004f52:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004f54:	00004597          	auipc	a1,0x4
    80004f58:	7c458593          	add	a1,a1,1988 # 80009718 <etext+0x718>
    80004f5c:	0001e517          	auipc	a0,0x1e
    80004f60:	62c50513          	add	a0,a0,1580 # 80023588 <ftable>
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	c44080e7          	jalr	-956(ra) # 80000ba8 <initlock>
}
    80004f6c:	60a2                	ld	ra,8(sp)
    80004f6e:	6402                	ld	s0,0(sp)
    80004f70:	0141                	add	sp,sp,16
    80004f72:	8082                	ret

0000000080004f74 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004f74:	1101                	add	sp,sp,-32
    80004f76:	ec06                	sd	ra,24(sp)
    80004f78:	e822                	sd	s0,16(sp)
    80004f7a:	e426                	sd	s1,8(sp)
    80004f7c:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004f7e:	0001e517          	auipc	a0,0x1e
    80004f82:	60a50513          	add	a0,a0,1546 # 80023588 <ftable>
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	cb2080e7          	jalr	-846(ra) # 80000c38 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f8e:	0001e497          	auipc	s1,0x1e
    80004f92:	61248493          	add	s1,s1,1554 # 800235a0 <ftable+0x18>
    80004f96:	0001f717          	auipc	a4,0x1f
    80004f9a:	5aa70713          	add	a4,a4,1450 # 80024540 <disk>
    if(f->ref == 0){
    80004f9e:	40dc                	lw	a5,4(s1)
    80004fa0:	cf99                	beqz	a5,80004fbe <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004fa2:	02848493          	add	s1,s1,40
    80004fa6:	fee49ce3          	bne	s1,a4,80004f9e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004faa:	0001e517          	auipc	a0,0x1e
    80004fae:	5de50513          	add	a0,a0,1502 # 80023588 <ftable>
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	d3a080e7          	jalr	-710(ra) # 80000cec <release>
  return 0;
    80004fba:	4481                	li	s1,0
    80004fbc:	a819                	j	80004fd2 <filealloc+0x5e>
      f->ref = 1;
    80004fbe:	4785                	li	a5,1
    80004fc0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004fc2:	0001e517          	auipc	a0,0x1e
    80004fc6:	5c650513          	add	a0,a0,1478 # 80023588 <ftable>
    80004fca:	ffffc097          	auipc	ra,0xffffc
    80004fce:	d22080e7          	jalr	-734(ra) # 80000cec <release>
}
    80004fd2:	8526                	mv	a0,s1
    80004fd4:	60e2                	ld	ra,24(sp)
    80004fd6:	6442                	ld	s0,16(sp)
    80004fd8:	64a2                	ld	s1,8(sp)
    80004fda:	6105                	add	sp,sp,32
    80004fdc:	8082                	ret

0000000080004fde <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004fde:	1101                	add	sp,sp,-32
    80004fe0:	ec06                	sd	ra,24(sp)
    80004fe2:	e822                	sd	s0,16(sp)
    80004fe4:	e426                	sd	s1,8(sp)
    80004fe6:	1000                	add	s0,sp,32
    80004fe8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004fea:	0001e517          	auipc	a0,0x1e
    80004fee:	59e50513          	add	a0,a0,1438 # 80023588 <ftable>
    80004ff2:	ffffc097          	auipc	ra,0xffffc
    80004ff6:	c46080e7          	jalr	-954(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004ffa:	40dc                	lw	a5,4(s1)
    80004ffc:	02f05263          	blez	a5,80005020 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005000:	2785                	addw	a5,a5,1
    80005002:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005004:	0001e517          	auipc	a0,0x1e
    80005008:	58450513          	add	a0,a0,1412 # 80023588 <ftable>
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	ce0080e7          	jalr	-800(ra) # 80000cec <release>
  return f;
}
    80005014:	8526                	mv	a0,s1
    80005016:	60e2                	ld	ra,24(sp)
    80005018:	6442                	ld	s0,16(sp)
    8000501a:	64a2                	ld	s1,8(sp)
    8000501c:	6105                	add	sp,sp,32
    8000501e:	8082                	ret
    panic("filedup");
    80005020:	00004517          	auipc	a0,0x4
    80005024:	70050513          	add	a0,a0,1792 # 80009720 <etext+0x720>
    80005028:	ffffb097          	auipc	ra,0xffffb
    8000502c:	538080e7          	jalr	1336(ra) # 80000560 <panic>

0000000080005030 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005030:	7139                	add	sp,sp,-64
    80005032:	fc06                	sd	ra,56(sp)
    80005034:	f822                	sd	s0,48(sp)
    80005036:	f426                	sd	s1,40(sp)
    80005038:	0080                	add	s0,sp,64
    8000503a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000503c:	0001e517          	auipc	a0,0x1e
    80005040:	54c50513          	add	a0,a0,1356 # 80023588 <ftable>
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	bf4080e7          	jalr	-1036(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    8000504c:	40dc                	lw	a5,4(s1)
    8000504e:	04f05c63          	blez	a5,800050a6 <fileclose+0x76>
    panic("fileclose");
  if(--f->ref > 0){
    80005052:	37fd                	addw	a5,a5,-1
    80005054:	0007871b          	sext.w	a4,a5
    80005058:	c0dc                	sw	a5,4(s1)
    8000505a:	06e04263          	bgtz	a4,800050be <fileclose+0x8e>
    8000505e:	f04a                	sd	s2,32(sp)
    80005060:	ec4e                	sd	s3,24(sp)
    80005062:	e852                	sd	s4,16(sp)
    80005064:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005066:	0004a903          	lw	s2,0(s1)
    8000506a:	0094ca83          	lbu	s5,9(s1)
    8000506e:	0104ba03          	ld	s4,16(s1)
    80005072:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005076:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000507a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000507e:	0001e517          	auipc	a0,0x1e
    80005082:	50a50513          	add	a0,a0,1290 # 80023588 <ftable>
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	c66080e7          	jalr	-922(ra) # 80000cec <release>

  if(ff.type == FD_PIPE){
    8000508e:	4785                	li	a5,1
    80005090:	04f90463          	beq	s2,a5,800050d8 <fileclose+0xa8>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005094:	3979                	addw	s2,s2,-2
    80005096:	4785                	li	a5,1
    80005098:	0527fb63          	bgeu	a5,s2,800050ee <fileclose+0xbe>
    8000509c:	7902                	ld	s2,32(sp)
    8000509e:	69e2                	ld	s3,24(sp)
    800050a0:	6a42                	ld	s4,16(sp)
    800050a2:	6aa2                	ld	s5,8(sp)
    800050a4:	a02d                	j	800050ce <fileclose+0x9e>
    800050a6:	f04a                	sd	s2,32(sp)
    800050a8:	ec4e                	sd	s3,24(sp)
    800050aa:	e852                	sd	s4,16(sp)
    800050ac:	e456                	sd	s5,8(sp)
    panic("fileclose");
    800050ae:	00004517          	auipc	a0,0x4
    800050b2:	67a50513          	add	a0,a0,1658 # 80009728 <etext+0x728>
    800050b6:	ffffb097          	auipc	ra,0xffffb
    800050ba:	4aa080e7          	jalr	1194(ra) # 80000560 <panic>
    release(&ftable.lock);
    800050be:	0001e517          	auipc	a0,0x1e
    800050c2:	4ca50513          	add	a0,a0,1226 # 80023588 <ftable>
    800050c6:	ffffc097          	auipc	ra,0xffffc
    800050ca:	c26080e7          	jalr	-986(ra) # 80000cec <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    800050ce:	70e2                	ld	ra,56(sp)
    800050d0:	7442                	ld	s0,48(sp)
    800050d2:	74a2                	ld	s1,40(sp)
    800050d4:	6121                	add	sp,sp,64
    800050d6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800050d8:	85d6                	mv	a1,s5
    800050da:	8552                	mv	a0,s4
    800050dc:	00000097          	auipc	ra,0x0
    800050e0:	3a2080e7          	jalr	930(ra) # 8000547e <pipeclose>
    800050e4:	7902                	ld	s2,32(sp)
    800050e6:	69e2                	ld	s3,24(sp)
    800050e8:	6a42                	ld	s4,16(sp)
    800050ea:	6aa2                	ld	s5,8(sp)
    800050ec:	b7cd                	j	800050ce <fileclose+0x9e>
    begin_op();
    800050ee:	00000097          	auipc	ra,0x0
    800050f2:	a78080e7          	jalr	-1416(ra) # 80004b66 <begin_op>
    iput(ff.ip);
    800050f6:	854e                	mv	a0,s3
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	25e080e7          	jalr	606(ra) # 80004356 <iput>
    end_op();
    80005100:	00000097          	auipc	ra,0x0
    80005104:	ae0080e7          	jalr	-1312(ra) # 80004be0 <end_op>
    80005108:	7902                	ld	s2,32(sp)
    8000510a:	69e2                	ld	s3,24(sp)
    8000510c:	6a42                	ld	s4,16(sp)
    8000510e:	6aa2                	ld	s5,8(sp)
    80005110:	bf7d                	j	800050ce <fileclose+0x9e>

0000000080005112 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005112:	715d                	add	sp,sp,-80
    80005114:	e486                	sd	ra,72(sp)
    80005116:	e0a2                	sd	s0,64(sp)
    80005118:	fc26                	sd	s1,56(sp)
    8000511a:	f44e                	sd	s3,40(sp)
    8000511c:	0880                	add	s0,sp,80
    8000511e:	84aa                	mv	s1,a0
    80005120:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005122:	ffffd097          	auipc	ra,0xffffd
    80005126:	a68080e7          	jalr	-1432(ra) # 80001b8a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000512a:	409c                	lw	a5,0(s1)
    8000512c:	37f9                	addw	a5,a5,-2
    8000512e:	4705                	li	a4,1
    80005130:	04f76863          	bltu	a4,a5,80005180 <filestat+0x6e>
    80005134:	f84a                	sd	s2,48(sp)
    80005136:	892a                	mv	s2,a0
    ilock(f->ip);
    80005138:	6c88                	ld	a0,24(s1)
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	05e080e7          	jalr	94(ra) # 80004198 <ilock>
    stati(f->ip, &st);
    80005142:	fb840593          	add	a1,s0,-72
    80005146:	6c88                	ld	a0,24(s1)
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	2de080e7          	jalr	734(ra) # 80004426 <stati>
    iunlock(f->ip);
    80005150:	6c88                	ld	a0,24(s1)
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	10c080e7          	jalr	268(ra) # 8000425e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000515a:	46e1                	li	a3,24
    8000515c:	fb840613          	add	a2,s0,-72
    80005160:	85ce                	mv	a1,s3
    80005162:	05093503          	ld	a0,80(s2)
    80005166:	ffffc097          	auipc	ra,0xffffc
    8000516a:	578080e7          	jalr	1400(ra) # 800016de <copyout>
    8000516e:	41f5551b          	sraw	a0,a0,0x1f
    80005172:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80005174:	60a6                	ld	ra,72(sp)
    80005176:	6406                	ld	s0,64(sp)
    80005178:	74e2                	ld	s1,56(sp)
    8000517a:	79a2                	ld	s3,40(sp)
    8000517c:	6161                	add	sp,sp,80
    8000517e:	8082                	ret
  return -1;
    80005180:	557d                	li	a0,-1
    80005182:	bfcd                	j	80005174 <filestat+0x62>

0000000080005184 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005184:	7179                	add	sp,sp,-48
    80005186:	f406                	sd	ra,40(sp)
    80005188:	f022                	sd	s0,32(sp)
    8000518a:	e84a                	sd	s2,16(sp)
    8000518c:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000518e:	00854783          	lbu	a5,8(a0)
    80005192:	cbc5                	beqz	a5,80005242 <fileread+0xbe>
    80005194:	ec26                	sd	s1,24(sp)
    80005196:	e44e                	sd	s3,8(sp)
    80005198:	84aa                	mv	s1,a0
    8000519a:	89ae                	mv	s3,a1
    8000519c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000519e:	411c                	lw	a5,0(a0)
    800051a0:	4705                	li	a4,1
    800051a2:	04e78963          	beq	a5,a4,800051f4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051a6:	470d                	li	a4,3
    800051a8:	04e78f63          	beq	a5,a4,80005206 <fileread+0x82>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800051ac:	4709                	li	a4,2
    800051ae:	08e79263          	bne	a5,a4,80005232 <fileread+0xae>
    ilock(f->ip);
    800051b2:	6d08                	ld	a0,24(a0)
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	fe4080e7          	jalr	-28(ra) # 80004198 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800051bc:	874a                	mv	a4,s2
    800051be:	5094                	lw	a3,32(s1)
    800051c0:	864e                	mv	a2,s3
    800051c2:	4585                	li	a1,1
    800051c4:	6c88                	ld	a0,24(s1)
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	28a080e7          	jalr	650(ra) # 80004450 <readi>
    800051ce:	892a                	mv	s2,a0
    800051d0:	00a05563          	blez	a0,800051da <fileread+0x56>
      f->off += r;
    800051d4:	509c                	lw	a5,32(s1)
    800051d6:	9fa9                	addw	a5,a5,a0
    800051d8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800051da:	6c88                	ld	a0,24(s1)
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	082080e7          	jalr	130(ra) # 8000425e <iunlock>
    800051e4:	64e2                	ld	s1,24(sp)
    800051e6:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    800051e8:	854a                	mv	a0,s2
    800051ea:	70a2                	ld	ra,40(sp)
    800051ec:	7402                	ld	s0,32(sp)
    800051ee:	6942                	ld	s2,16(sp)
    800051f0:	6145                	add	sp,sp,48
    800051f2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800051f4:	6908                	ld	a0,16(a0)
    800051f6:	00000097          	auipc	ra,0x0
    800051fa:	400080e7          	jalr	1024(ra) # 800055f6 <piperead>
    800051fe:	892a                	mv	s2,a0
    80005200:	64e2                	ld	s1,24(sp)
    80005202:	69a2                	ld	s3,8(sp)
    80005204:	b7d5                	j	800051e8 <fileread+0x64>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005206:	02451783          	lh	a5,36(a0)
    8000520a:	03079693          	sll	a3,a5,0x30
    8000520e:	92c1                	srl	a3,a3,0x30
    80005210:	4725                	li	a4,9
    80005212:	02d76a63          	bltu	a4,a3,80005246 <fileread+0xc2>
    80005216:	0792                	sll	a5,a5,0x4
    80005218:	0001e717          	auipc	a4,0x1e
    8000521c:	2d070713          	add	a4,a4,720 # 800234e8 <devsw>
    80005220:	97ba                	add	a5,a5,a4
    80005222:	639c                	ld	a5,0(a5)
    80005224:	c78d                	beqz	a5,8000524e <fileread+0xca>
    r = devsw[f->major].read(1, addr, n);
    80005226:	4505                	li	a0,1
    80005228:	9782                	jalr	a5
    8000522a:	892a                	mv	s2,a0
    8000522c:	64e2                	ld	s1,24(sp)
    8000522e:	69a2                	ld	s3,8(sp)
    80005230:	bf65                	j	800051e8 <fileread+0x64>
    panic("fileread");
    80005232:	00004517          	auipc	a0,0x4
    80005236:	50650513          	add	a0,a0,1286 # 80009738 <etext+0x738>
    8000523a:	ffffb097          	auipc	ra,0xffffb
    8000523e:	326080e7          	jalr	806(ra) # 80000560 <panic>
    return -1;
    80005242:	597d                	li	s2,-1
    80005244:	b755                	j	800051e8 <fileread+0x64>
      return -1;
    80005246:	597d                	li	s2,-1
    80005248:	64e2                	ld	s1,24(sp)
    8000524a:	69a2                	ld	s3,8(sp)
    8000524c:	bf71                	j	800051e8 <fileread+0x64>
    8000524e:	597d                	li	s2,-1
    80005250:	64e2                	ld	s1,24(sp)
    80005252:	69a2                	ld	s3,8(sp)
    80005254:	bf51                	j	800051e8 <fileread+0x64>

0000000080005256 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80005256:	00954783          	lbu	a5,9(a0)
    8000525a:	12078963          	beqz	a5,8000538c <filewrite+0x136>
{
    8000525e:	715d                	add	sp,sp,-80
    80005260:	e486                	sd	ra,72(sp)
    80005262:	e0a2                	sd	s0,64(sp)
    80005264:	f84a                	sd	s2,48(sp)
    80005266:	f052                	sd	s4,32(sp)
    80005268:	e85a                	sd	s6,16(sp)
    8000526a:	0880                	add	s0,sp,80
    8000526c:	892a                	mv	s2,a0
    8000526e:	8b2e                	mv	s6,a1
    80005270:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005272:	411c                	lw	a5,0(a0)
    80005274:	4705                	li	a4,1
    80005276:	02e78763          	beq	a5,a4,800052a4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000527a:	470d                	li	a4,3
    8000527c:	02e78a63          	beq	a5,a4,800052b0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005280:	4709                	li	a4,2
    80005282:	0ee79863          	bne	a5,a4,80005372 <filewrite+0x11c>
    80005286:	f44e                	sd	s3,40(sp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005288:	0cc05463          	blez	a2,80005350 <filewrite+0xfa>
    8000528c:	fc26                	sd	s1,56(sp)
    8000528e:	ec56                	sd	s5,24(sp)
    80005290:	e45e                	sd	s7,8(sp)
    80005292:	e062                	sd	s8,0(sp)
    int i = 0;
    80005294:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80005296:	6b85                	lui	s7,0x1
    80005298:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000529c:	6c05                	lui	s8,0x1
    8000529e:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800052a2:	a851                	j	80005336 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800052a4:	6908                	ld	a0,16(a0)
    800052a6:	00000097          	auipc	ra,0x0
    800052aa:	248080e7          	jalr	584(ra) # 800054ee <pipewrite>
    800052ae:	a85d                	j	80005364 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800052b0:	02451783          	lh	a5,36(a0)
    800052b4:	03079693          	sll	a3,a5,0x30
    800052b8:	92c1                	srl	a3,a3,0x30
    800052ba:	4725                	li	a4,9
    800052bc:	0cd76a63          	bltu	a4,a3,80005390 <filewrite+0x13a>
    800052c0:	0792                	sll	a5,a5,0x4
    800052c2:	0001e717          	auipc	a4,0x1e
    800052c6:	22670713          	add	a4,a4,550 # 800234e8 <devsw>
    800052ca:	97ba                	add	a5,a5,a4
    800052cc:	679c                	ld	a5,8(a5)
    800052ce:	c3f9                	beqz	a5,80005394 <filewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    800052d0:	4505                	li	a0,1
    800052d2:	9782                	jalr	a5
    800052d4:	a841                	j	80005364 <filewrite+0x10e>
      if(n1 > max)
    800052d6:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800052da:	00000097          	auipc	ra,0x0
    800052de:	88c080e7          	jalr	-1908(ra) # 80004b66 <begin_op>
      ilock(f->ip);
    800052e2:	01893503          	ld	a0,24(s2)
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	eb2080e7          	jalr	-334(ra) # 80004198 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800052ee:	8756                	mv	a4,s5
    800052f0:	02092683          	lw	a3,32(s2)
    800052f4:	01698633          	add	a2,s3,s6
    800052f8:	4585                	li	a1,1
    800052fa:	01893503          	ld	a0,24(s2)
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	262080e7          	jalr	610(ra) # 80004560 <writei>
    80005306:	84aa                	mv	s1,a0
    80005308:	00a05763          	blez	a0,80005316 <filewrite+0xc0>
        f->off += r;
    8000530c:	02092783          	lw	a5,32(s2)
    80005310:	9fa9                	addw	a5,a5,a0
    80005312:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005316:	01893503          	ld	a0,24(s2)
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	f44080e7          	jalr	-188(ra) # 8000425e <iunlock>
      end_op();
    80005322:	00000097          	auipc	ra,0x0
    80005326:	8be080e7          	jalr	-1858(ra) # 80004be0 <end_op>

      if(r != n1){
    8000532a:	029a9563          	bne	s5,s1,80005354 <filewrite+0xfe>
        // error from writei
        break;
      }
      i += r;
    8000532e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005332:	0149da63          	bge	s3,s4,80005346 <filewrite+0xf0>
      int n1 = n - i;
    80005336:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000533a:	0004879b          	sext.w	a5,s1
    8000533e:	f8fbdce3          	bge	s7,a5,800052d6 <filewrite+0x80>
    80005342:	84e2                	mv	s1,s8
    80005344:	bf49                	j	800052d6 <filewrite+0x80>
    80005346:	74e2                	ld	s1,56(sp)
    80005348:	6ae2                	ld	s5,24(sp)
    8000534a:	6ba2                	ld	s7,8(sp)
    8000534c:	6c02                	ld	s8,0(sp)
    8000534e:	a039                	j	8000535c <filewrite+0x106>
    int i = 0;
    80005350:	4981                	li	s3,0
    80005352:	a029                	j	8000535c <filewrite+0x106>
    80005354:	74e2                	ld	s1,56(sp)
    80005356:	6ae2                	ld	s5,24(sp)
    80005358:	6ba2                	ld	s7,8(sp)
    8000535a:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    8000535c:	033a1e63          	bne	s4,s3,80005398 <filewrite+0x142>
    80005360:	8552                	mv	a0,s4
    80005362:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005364:	60a6                	ld	ra,72(sp)
    80005366:	6406                	ld	s0,64(sp)
    80005368:	7942                	ld	s2,48(sp)
    8000536a:	7a02                	ld	s4,32(sp)
    8000536c:	6b42                	ld	s6,16(sp)
    8000536e:	6161                	add	sp,sp,80
    80005370:	8082                	ret
    80005372:	fc26                	sd	s1,56(sp)
    80005374:	f44e                	sd	s3,40(sp)
    80005376:	ec56                	sd	s5,24(sp)
    80005378:	e45e                	sd	s7,8(sp)
    8000537a:	e062                	sd	s8,0(sp)
    panic("filewrite");
    8000537c:	00004517          	auipc	a0,0x4
    80005380:	3cc50513          	add	a0,a0,972 # 80009748 <etext+0x748>
    80005384:	ffffb097          	auipc	ra,0xffffb
    80005388:	1dc080e7          	jalr	476(ra) # 80000560 <panic>
    return -1;
    8000538c:	557d                	li	a0,-1
}
    8000538e:	8082                	ret
      return -1;
    80005390:	557d                	li	a0,-1
    80005392:	bfc9                	j	80005364 <filewrite+0x10e>
    80005394:	557d                	li	a0,-1
    80005396:	b7f9                	j	80005364 <filewrite+0x10e>
    ret = (i == n ? n : -1);
    80005398:	557d                	li	a0,-1
    8000539a:	79a2                	ld	s3,40(sp)
    8000539c:	b7e1                	j	80005364 <filewrite+0x10e>

000000008000539e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000539e:	7179                	add	sp,sp,-48
    800053a0:	f406                	sd	ra,40(sp)
    800053a2:	f022                	sd	s0,32(sp)
    800053a4:	ec26                	sd	s1,24(sp)
    800053a6:	e052                	sd	s4,0(sp)
    800053a8:	1800                	add	s0,sp,48
    800053aa:	84aa                	mv	s1,a0
    800053ac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800053ae:	0005b023          	sd	zero,0(a1)
    800053b2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800053b6:	00000097          	auipc	ra,0x0
    800053ba:	bbe080e7          	jalr	-1090(ra) # 80004f74 <filealloc>
    800053be:	e088                	sd	a0,0(s1)
    800053c0:	cd49                	beqz	a0,8000545a <pipealloc+0xbc>
    800053c2:	00000097          	auipc	ra,0x0
    800053c6:	bb2080e7          	jalr	-1102(ra) # 80004f74 <filealloc>
    800053ca:	00aa3023          	sd	a0,0(s4)
    800053ce:	c141                	beqz	a0,8000544e <pipealloc+0xb0>
    800053d0:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800053d2:	ffffb097          	auipc	ra,0xffffb
    800053d6:	776080e7          	jalr	1910(ra) # 80000b48 <kalloc>
    800053da:	892a                	mv	s2,a0
    800053dc:	c13d                	beqz	a0,80005442 <pipealloc+0xa4>
    800053de:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    800053e0:	4985                	li	s3,1
    800053e2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800053e6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800053ea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800053ee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800053f2:	00004597          	auipc	a1,0x4
    800053f6:	0ae58593          	add	a1,a1,174 # 800094a0 <etext+0x4a0>
    800053fa:	ffffb097          	auipc	ra,0xffffb
    800053fe:	7ae080e7          	jalr	1966(ra) # 80000ba8 <initlock>
  (*f0)->type = FD_PIPE;
    80005402:	609c                	ld	a5,0(s1)
    80005404:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005408:	609c                	ld	a5,0(s1)
    8000540a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000540e:	609c                	ld	a5,0(s1)
    80005410:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005414:	609c                	ld	a5,0(s1)
    80005416:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000541a:	000a3783          	ld	a5,0(s4)
    8000541e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005422:	000a3783          	ld	a5,0(s4)
    80005426:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000542a:	000a3783          	ld	a5,0(s4)
    8000542e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005432:	000a3783          	ld	a5,0(s4)
    80005436:	0127b823          	sd	s2,16(a5)
  return 0;
    8000543a:	4501                	li	a0,0
    8000543c:	6942                	ld	s2,16(sp)
    8000543e:	69a2                	ld	s3,8(sp)
    80005440:	a03d                	j	8000546e <pipealloc+0xd0>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005442:	6088                	ld	a0,0(s1)
    80005444:	c119                	beqz	a0,8000544a <pipealloc+0xac>
    80005446:	6942                	ld	s2,16(sp)
    80005448:	a029                	j	80005452 <pipealloc+0xb4>
    8000544a:	6942                	ld	s2,16(sp)
    8000544c:	a039                	j	8000545a <pipealloc+0xbc>
    8000544e:	6088                	ld	a0,0(s1)
    80005450:	c50d                	beqz	a0,8000547a <pipealloc+0xdc>
    fileclose(*f0);
    80005452:	00000097          	auipc	ra,0x0
    80005456:	bde080e7          	jalr	-1058(ra) # 80005030 <fileclose>
  if(*f1)
    8000545a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000545e:	557d                	li	a0,-1
  if(*f1)
    80005460:	c799                	beqz	a5,8000546e <pipealloc+0xd0>
    fileclose(*f1);
    80005462:	853e                	mv	a0,a5
    80005464:	00000097          	auipc	ra,0x0
    80005468:	bcc080e7          	jalr	-1076(ra) # 80005030 <fileclose>
  return -1;
    8000546c:	557d                	li	a0,-1
}
    8000546e:	70a2                	ld	ra,40(sp)
    80005470:	7402                	ld	s0,32(sp)
    80005472:	64e2                	ld	s1,24(sp)
    80005474:	6a02                	ld	s4,0(sp)
    80005476:	6145                	add	sp,sp,48
    80005478:	8082                	ret
  return -1;
    8000547a:	557d                	li	a0,-1
    8000547c:	bfcd                	j	8000546e <pipealloc+0xd0>

000000008000547e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000547e:	1101                	add	sp,sp,-32
    80005480:	ec06                	sd	ra,24(sp)
    80005482:	e822                	sd	s0,16(sp)
    80005484:	e426                	sd	s1,8(sp)
    80005486:	e04a                	sd	s2,0(sp)
    80005488:	1000                	add	s0,sp,32
    8000548a:	84aa                	mv	s1,a0
    8000548c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000548e:	ffffb097          	auipc	ra,0xffffb
    80005492:	7aa080e7          	jalr	1962(ra) # 80000c38 <acquire>
  if(writable){
    80005496:	02090d63          	beqz	s2,800054d0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000549a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000549e:	21848513          	add	a0,s1,536
    800054a2:	ffffd097          	auipc	ra,0xffffd
    800054a6:	1de080e7          	jalr	478(ra) # 80002680 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800054aa:	2204b783          	ld	a5,544(s1)
    800054ae:	eb95                	bnez	a5,800054e2 <pipeclose+0x64>
    release(&pi->lock);
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffc097          	auipc	ra,0xffffc
    800054b6:	83a080e7          	jalr	-1990(ra) # 80000cec <release>
    kfree((char*)pi);
    800054ba:	8526                	mv	a0,s1
    800054bc:	ffffb097          	auipc	ra,0xffffb
    800054c0:	58e080e7          	jalr	1422(ra) # 80000a4a <kfree>
  } else
    release(&pi->lock);
}
    800054c4:	60e2                	ld	ra,24(sp)
    800054c6:	6442                	ld	s0,16(sp)
    800054c8:	64a2                	ld	s1,8(sp)
    800054ca:	6902                	ld	s2,0(sp)
    800054cc:	6105                	add	sp,sp,32
    800054ce:	8082                	ret
    pi->readopen = 0;
    800054d0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800054d4:	21c48513          	add	a0,s1,540
    800054d8:	ffffd097          	auipc	ra,0xffffd
    800054dc:	1a8080e7          	jalr	424(ra) # 80002680 <wakeup>
    800054e0:	b7e9                	j	800054aa <pipeclose+0x2c>
    release(&pi->lock);
    800054e2:	8526                	mv	a0,s1
    800054e4:	ffffc097          	auipc	ra,0xffffc
    800054e8:	808080e7          	jalr	-2040(ra) # 80000cec <release>
}
    800054ec:	bfe1                	j	800054c4 <pipeclose+0x46>

00000000800054ee <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800054ee:	711d                	add	sp,sp,-96
    800054f0:	ec86                	sd	ra,88(sp)
    800054f2:	e8a2                	sd	s0,80(sp)
    800054f4:	e4a6                	sd	s1,72(sp)
    800054f6:	e0ca                	sd	s2,64(sp)
    800054f8:	fc4e                	sd	s3,56(sp)
    800054fa:	f852                	sd	s4,48(sp)
    800054fc:	f456                	sd	s5,40(sp)
    800054fe:	1080                	add	s0,sp,96
    80005500:	84aa                	mv	s1,a0
    80005502:	8aae                	mv	s5,a1
    80005504:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005506:	ffffc097          	auipc	ra,0xffffc
    8000550a:	684080e7          	jalr	1668(ra) # 80001b8a <myproc>
    8000550e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffb097          	auipc	ra,0xffffb
    80005516:	726080e7          	jalr	1830(ra) # 80000c38 <acquire>
  while(i < n){
    8000551a:	0d405863          	blez	s4,800055ea <pipewrite+0xfc>
    8000551e:	f05a                	sd	s6,32(sp)
    80005520:	ec5e                	sd	s7,24(sp)
    80005522:	e862                	sd	s8,16(sp)
  int i = 0;
    80005524:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005526:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005528:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000552c:	21c48b93          	add	s7,s1,540
    80005530:	a089                	j	80005572 <pipewrite+0x84>
      release(&pi->lock);
    80005532:	8526                	mv	a0,s1
    80005534:	ffffb097          	auipc	ra,0xffffb
    80005538:	7b8080e7          	jalr	1976(ra) # 80000cec <release>
      return -1;
    8000553c:	597d                	li	s2,-1
    8000553e:	7b02                	ld	s6,32(sp)
    80005540:	6be2                	ld	s7,24(sp)
    80005542:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005544:	854a                	mv	a0,s2
    80005546:	60e6                	ld	ra,88(sp)
    80005548:	6446                	ld	s0,80(sp)
    8000554a:	64a6                	ld	s1,72(sp)
    8000554c:	6906                	ld	s2,64(sp)
    8000554e:	79e2                	ld	s3,56(sp)
    80005550:	7a42                	ld	s4,48(sp)
    80005552:	7aa2                	ld	s5,40(sp)
    80005554:	6125                	add	sp,sp,96
    80005556:	8082                	ret
      wakeup(&pi->nread);
    80005558:	8562                	mv	a0,s8
    8000555a:	ffffd097          	auipc	ra,0xffffd
    8000555e:	126080e7          	jalr	294(ra) # 80002680 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005562:	85a6                	mv	a1,s1
    80005564:	855e                	mv	a0,s7
    80005566:	ffffd097          	auipc	ra,0xffffd
    8000556a:	f6a080e7          	jalr	-150(ra) # 800024d0 <sleep>
  while(i < n){
    8000556e:	05495f63          	bge	s2,s4,800055cc <pipewrite+0xde>
    if(pi->readopen == 0 || killed(pr)){
    80005572:	2204a783          	lw	a5,544(s1)
    80005576:	dfd5                	beqz	a5,80005532 <pipewrite+0x44>
    80005578:	854e                	mv	a0,s3
    8000557a:	ffffd097          	auipc	ra,0xffffd
    8000557e:	356080e7          	jalr	854(ra) # 800028d0 <killed>
    80005582:	f945                	bnez	a0,80005532 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005584:	2184a783          	lw	a5,536(s1)
    80005588:	21c4a703          	lw	a4,540(s1)
    8000558c:	2007879b          	addw	a5,a5,512
    80005590:	fcf704e3          	beq	a4,a5,80005558 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005594:	4685                	li	a3,1
    80005596:	01590633          	add	a2,s2,s5
    8000559a:	faf40593          	add	a1,s0,-81
    8000559e:	0509b503          	ld	a0,80(s3)
    800055a2:	ffffc097          	auipc	ra,0xffffc
    800055a6:	290080e7          	jalr	656(ra) # 80001832 <copyin>
    800055aa:	05650263          	beq	a0,s6,800055ee <pipewrite+0x100>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800055ae:	21c4a783          	lw	a5,540(s1)
    800055b2:	0017871b          	addw	a4,a5,1
    800055b6:	20e4ae23          	sw	a4,540(s1)
    800055ba:	1ff7f793          	and	a5,a5,511
    800055be:	97a6                	add	a5,a5,s1
    800055c0:	faf44703          	lbu	a4,-81(s0)
    800055c4:	00e78c23          	sb	a4,24(a5)
      i++;
    800055c8:	2905                	addw	s2,s2,1
    800055ca:	b755                	j	8000556e <pipewrite+0x80>
    800055cc:	7b02                	ld	s6,32(sp)
    800055ce:	6be2                	ld	s7,24(sp)
    800055d0:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    800055d2:	21848513          	add	a0,s1,536
    800055d6:	ffffd097          	auipc	ra,0xffffd
    800055da:	0aa080e7          	jalr	170(ra) # 80002680 <wakeup>
  release(&pi->lock);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffb097          	auipc	ra,0xffffb
    800055e4:	70c080e7          	jalr	1804(ra) # 80000cec <release>
  return i;
    800055e8:	bfb1                	j	80005544 <pipewrite+0x56>
  int i = 0;
    800055ea:	4901                	li	s2,0
    800055ec:	b7dd                	j	800055d2 <pipewrite+0xe4>
    800055ee:	7b02                	ld	s6,32(sp)
    800055f0:	6be2                	ld	s7,24(sp)
    800055f2:	6c42                	ld	s8,16(sp)
    800055f4:	bff9                	j	800055d2 <pipewrite+0xe4>

00000000800055f6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800055f6:	715d                	add	sp,sp,-80
    800055f8:	e486                	sd	ra,72(sp)
    800055fa:	e0a2                	sd	s0,64(sp)
    800055fc:	fc26                	sd	s1,56(sp)
    800055fe:	f84a                	sd	s2,48(sp)
    80005600:	f44e                	sd	s3,40(sp)
    80005602:	f052                	sd	s4,32(sp)
    80005604:	ec56                	sd	s5,24(sp)
    80005606:	0880                	add	s0,sp,80
    80005608:	84aa                	mv	s1,a0
    8000560a:	892e                	mv	s2,a1
    8000560c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000560e:	ffffc097          	auipc	ra,0xffffc
    80005612:	57c080e7          	jalr	1404(ra) # 80001b8a <myproc>
    80005616:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffb097          	auipc	ra,0xffffb
    8000561e:	61e080e7          	jalr	1566(ra) # 80000c38 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005622:	2184a703          	lw	a4,536(s1)
    80005626:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000562a:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000562e:	02f71963          	bne	a4,a5,80005660 <piperead+0x6a>
    80005632:	2244a783          	lw	a5,548(s1)
    80005636:	cf95                	beqz	a5,80005672 <piperead+0x7c>
    if(killed(pr)){
    80005638:	8552                	mv	a0,s4
    8000563a:	ffffd097          	auipc	ra,0xffffd
    8000563e:	296080e7          	jalr	662(ra) # 800028d0 <killed>
    80005642:	e10d                	bnez	a0,80005664 <piperead+0x6e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005644:	85a6                	mv	a1,s1
    80005646:	854e                	mv	a0,s3
    80005648:	ffffd097          	auipc	ra,0xffffd
    8000564c:	e88080e7          	jalr	-376(ra) # 800024d0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005650:	2184a703          	lw	a4,536(s1)
    80005654:	21c4a783          	lw	a5,540(s1)
    80005658:	fcf70de3          	beq	a4,a5,80005632 <piperead+0x3c>
    8000565c:	e85a                	sd	s6,16(sp)
    8000565e:	a819                	j	80005674 <piperead+0x7e>
    80005660:	e85a                	sd	s6,16(sp)
    80005662:	a809                	j	80005674 <piperead+0x7e>
      release(&pi->lock);
    80005664:	8526                	mv	a0,s1
    80005666:	ffffb097          	auipc	ra,0xffffb
    8000566a:	686080e7          	jalr	1670(ra) # 80000cec <release>
      return -1;
    8000566e:	59fd                	li	s3,-1
    80005670:	a0a5                	j	800056d8 <piperead+0xe2>
    80005672:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005674:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005676:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005678:	05505463          	blez	s5,800056c0 <piperead+0xca>
    if(pi->nread == pi->nwrite)
    8000567c:	2184a783          	lw	a5,536(s1)
    80005680:	21c4a703          	lw	a4,540(s1)
    80005684:	02f70e63          	beq	a4,a5,800056c0 <piperead+0xca>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005688:	0017871b          	addw	a4,a5,1
    8000568c:	20e4ac23          	sw	a4,536(s1)
    80005690:	1ff7f793          	and	a5,a5,511
    80005694:	97a6                	add	a5,a5,s1
    80005696:	0187c783          	lbu	a5,24(a5)
    8000569a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000569e:	4685                	li	a3,1
    800056a0:	fbf40613          	add	a2,s0,-65
    800056a4:	85ca                	mv	a1,s2
    800056a6:	050a3503          	ld	a0,80(s4)
    800056aa:	ffffc097          	auipc	ra,0xffffc
    800056ae:	034080e7          	jalr	52(ra) # 800016de <copyout>
    800056b2:	01650763          	beq	a0,s6,800056c0 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800056b6:	2985                	addw	s3,s3,1
    800056b8:	0905                	add	s2,s2,1
    800056ba:	fd3a91e3          	bne	s5,s3,8000567c <piperead+0x86>
    800056be:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800056c0:	21c48513          	add	a0,s1,540
    800056c4:	ffffd097          	auipc	ra,0xffffd
    800056c8:	fbc080e7          	jalr	-68(ra) # 80002680 <wakeup>
  release(&pi->lock);
    800056cc:	8526                	mv	a0,s1
    800056ce:	ffffb097          	auipc	ra,0xffffb
    800056d2:	61e080e7          	jalr	1566(ra) # 80000cec <release>
    800056d6:	6b42                	ld	s6,16(sp)
  return i;
}
    800056d8:	854e                	mv	a0,s3
    800056da:	60a6                	ld	ra,72(sp)
    800056dc:	6406                	ld	s0,64(sp)
    800056de:	74e2                	ld	s1,56(sp)
    800056e0:	7942                	ld	s2,48(sp)
    800056e2:	79a2                	ld	s3,40(sp)
    800056e4:	7a02                	ld	s4,32(sp)
    800056e6:	6ae2                	ld	s5,24(sp)
    800056e8:	6161                	add	sp,sp,80
    800056ea:	8082                	ret

00000000800056ec <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800056ec:	1141                	add	sp,sp,-16
    800056ee:	e422                	sd	s0,8(sp)
    800056f0:	0800                	add	s0,sp,16
    800056f2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800056f4:	8905                	and	a0,a0,1
    800056f6:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800056f8:	8b89                	and	a5,a5,2
    800056fa:	c399                	beqz	a5,80005700 <flags2perm+0x14>
      perm |= PTE_W;
    800056fc:	00456513          	or	a0,a0,4
    return perm;
}
    80005700:	6422                	ld	s0,8(sp)
    80005702:	0141                	add	sp,sp,16
    80005704:	8082                	ret

0000000080005706 <exec>:

int
exec(char *path, char **argv)
{
    80005706:	df010113          	add	sp,sp,-528
    8000570a:	20113423          	sd	ra,520(sp)
    8000570e:	20813023          	sd	s0,512(sp)
    80005712:	ffa6                	sd	s1,504(sp)
    80005714:	fbca                	sd	s2,496(sp)
    80005716:	0c00                	add	s0,sp,528
    80005718:	892a                	mv	s2,a0
    8000571a:	dea43c23          	sd	a0,-520(s0)
    8000571e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005722:	ffffc097          	auipc	ra,0xffffc
    80005726:	468080e7          	jalr	1128(ra) # 80001b8a <myproc>
    8000572a:	84aa                	mv	s1,a0

  begin_op();
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	43a080e7          	jalr	1082(ra) # 80004b66 <begin_op>

  if((ip = namei(path)) == 0){
    80005734:	854a                	mv	a0,s2
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	230080e7          	jalr	560(ra) # 80004966 <namei>
    8000573e:	c135                	beqz	a0,800057a2 <exec+0x9c>
    80005740:	f3d2                	sd	s4,480(sp)
    80005742:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	a54080e7          	jalr	-1452(ra) # 80004198 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000574c:	04000713          	li	a4,64
    80005750:	4681                	li	a3,0
    80005752:	e5040613          	add	a2,s0,-432
    80005756:	4581                	li	a1,0
    80005758:	8552                	mv	a0,s4
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	cf6080e7          	jalr	-778(ra) # 80004450 <readi>
    80005762:	04000793          	li	a5,64
    80005766:	00f51a63          	bne	a0,a5,8000577a <exec+0x74>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000576a:	e5042703          	lw	a4,-432(s0)
    8000576e:	464c47b7          	lui	a5,0x464c4
    80005772:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005776:	02f70c63          	beq	a4,a5,800057ae <exec+0xa8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000577a:	8552                	mv	a0,s4
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	c82080e7          	jalr	-894(ra) # 800043fe <iunlockput>
    end_op();
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	45c080e7          	jalr	1116(ra) # 80004be0 <end_op>
  }
  return -1;
    8000578c:	557d                	li	a0,-1
    8000578e:	7a1e                	ld	s4,480(sp)
}
    80005790:	20813083          	ld	ra,520(sp)
    80005794:	20013403          	ld	s0,512(sp)
    80005798:	74fe                	ld	s1,504(sp)
    8000579a:	795e                	ld	s2,496(sp)
    8000579c:	21010113          	add	sp,sp,528
    800057a0:	8082                	ret
    end_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	43e080e7          	jalr	1086(ra) # 80004be0 <end_op>
    return -1;
    800057aa:	557d                	li	a0,-1
    800057ac:	b7d5                	j	80005790 <exec+0x8a>
    800057ae:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffc097          	auipc	ra,0xffffc
    800057b6:	49c080e7          	jalr	1180(ra) # 80001c4e <proc_pagetable>
    800057ba:	8b2a                	mv	s6,a0
    800057bc:	30050f63          	beqz	a0,80005ada <exec+0x3d4>
    800057c0:	f7ce                	sd	s3,488(sp)
    800057c2:	efd6                	sd	s5,472(sp)
    800057c4:	e7de                	sd	s7,456(sp)
    800057c6:	e3e2                	sd	s8,448(sp)
    800057c8:	ff66                	sd	s9,440(sp)
    800057ca:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057cc:	e7042d03          	lw	s10,-400(s0)
    800057d0:	e8845783          	lhu	a5,-376(s0)
    800057d4:	14078d63          	beqz	a5,8000592e <exec+0x228>
    800057d8:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800057da:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057dc:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800057de:	6c85                	lui	s9,0x1
    800057e0:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    800057e4:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800057e8:	6a85                	lui	s5,0x1
    800057ea:	a0b5                	j	80005856 <exec+0x150>
      panic("loadseg: address should exist");
    800057ec:	00004517          	auipc	a0,0x4
    800057f0:	f6c50513          	add	a0,a0,-148 # 80009758 <etext+0x758>
    800057f4:	ffffb097          	auipc	ra,0xffffb
    800057f8:	d6c080e7          	jalr	-660(ra) # 80000560 <panic>
    if(sz - i < PGSIZE)
    800057fc:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800057fe:	8726                	mv	a4,s1
    80005800:	012c06bb          	addw	a3,s8,s2
    80005804:	4581                	li	a1,0
    80005806:	8552                	mv	a0,s4
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	c48080e7          	jalr	-952(ra) # 80004450 <readi>
    80005810:	2501                	sext.w	a0,a0
    80005812:	28a49863          	bne	s1,a0,80005aa2 <exec+0x39c>
  for(i = 0; i < sz; i += PGSIZE){
    80005816:	012a893b          	addw	s2,s5,s2
    8000581a:	03397563          	bgeu	s2,s3,80005844 <exec+0x13e>
    pa = walkaddr(pagetable, va + i);
    8000581e:	02091593          	sll	a1,s2,0x20
    80005822:	9181                	srl	a1,a1,0x20
    80005824:	95de                	add	a1,a1,s7
    80005826:	855a                	mv	a0,s6
    80005828:	ffffc097          	auipc	ra,0xffffc
    8000582c:	896080e7          	jalr	-1898(ra) # 800010be <walkaddr>
    80005830:	862a                	mv	a2,a0
    if(pa == 0)
    80005832:	dd4d                	beqz	a0,800057ec <exec+0xe6>
    if(sz - i < PGSIZE)
    80005834:	412984bb          	subw	s1,s3,s2
    80005838:	0004879b          	sext.w	a5,s1
    8000583c:	fcfcf0e3          	bgeu	s9,a5,800057fc <exec+0xf6>
    80005840:	84d6                	mv	s1,s5
    80005842:	bf6d                	j	800057fc <exec+0xf6>
    sz = sz1;
    80005844:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005848:	2d85                	addw	s11,s11,1
    8000584a:	038d0d1b          	addw	s10,s10,56
    8000584e:	e8845783          	lhu	a5,-376(s0)
    80005852:	08fdd663          	bge	s11,a5,800058de <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005856:	2d01                	sext.w	s10,s10
    80005858:	03800713          	li	a4,56
    8000585c:	86ea                	mv	a3,s10
    8000585e:	e1840613          	add	a2,s0,-488
    80005862:	4581                	li	a1,0
    80005864:	8552                	mv	a0,s4
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	bea080e7          	jalr	-1046(ra) # 80004450 <readi>
    8000586e:	03800793          	li	a5,56
    80005872:	20f51063          	bne	a0,a5,80005a72 <exec+0x36c>
    if(ph.type != ELF_PROG_LOAD)
    80005876:	e1842783          	lw	a5,-488(s0)
    8000587a:	4705                	li	a4,1
    8000587c:	fce796e3          	bne	a5,a4,80005848 <exec+0x142>
    if(ph.memsz < ph.filesz)
    80005880:	e4043483          	ld	s1,-448(s0)
    80005884:	e3843783          	ld	a5,-456(s0)
    80005888:	1ef4e963          	bltu	s1,a5,80005a7a <exec+0x374>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000588c:	e2843783          	ld	a5,-472(s0)
    80005890:	94be                	add	s1,s1,a5
    80005892:	1ef4e863          	bltu	s1,a5,80005a82 <exec+0x37c>
    if(ph.vaddr % PGSIZE != 0)
    80005896:	df043703          	ld	a4,-528(s0)
    8000589a:	8ff9                	and	a5,a5,a4
    8000589c:	1e079763          	bnez	a5,80005a8a <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800058a0:	e1c42503          	lw	a0,-484(s0)
    800058a4:	00000097          	auipc	ra,0x0
    800058a8:	e48080e7          	jalr	-440(ra) # 800056ec <flags2perm>
    800058ac:	86aa                	mv	a3,a0
    800058ae:	8626                	mv	a2,s1
    800058b0:	85ca                	mv	a1,s2
    800058b2:	855a                	mv	a0,s6
    800058b4:	ffffc097          	auipc	ra,0xffffc
    800058b8:	bce080e7          	jalr	-1074(ra) # 80001482 <uvmalloc>
    800058bc:	e0a43423          	sd	a0,-504(s0)
    800058c0:	1c050963          	beqz	a0,80005a92 <exec+0x38c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800058c4:	e2843b83          	ld	s7,-472(s0)
    800058c8:	e2042c03          	lw	s8,-480(s0)
    800058cc:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800058d0:	00098463          	beqz	s3,800058d8 <exec+0x1d2>
    800058d4:	4901                	li	s2,0
    800058d6:	b7a1                	j	8000581e <exec+0x118>
    sz = sz1;
    800058d8:	e0843903          	ld	s2,-504(s0)
    800058dc:	b7b5                	j	80005848 <exec+0x142>
    800058de:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    800058e0:	8552                	mv	a0,s4
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	b1c080e7          	jalr	-1252(ra) # 800043fe <iunlockput>
  end_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	2f6080e7          	jalr	758(ra) # 80004be0 <end_op>
  p = myproc();
    800058f2:	ffffc097          	auipc	ra,0xffffc
    800058f6:	298080e7          	jalr	664(ra) # 80001b8a <myproc>
    800058fa:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800058fc:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005900:	6985                	lui	s3,0x1
    80005902:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005904:	99ca                	add	s3,s3,s2
    80005906:	77fd                	lui	a5,0xfffff
    80005908:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000590c:	4691                	li	a3,4
    8000590e:	6609                	lui	a2,0x2
    80005910:	964e                	add	a2,a2,s3
    80005912:	85ce                	mv	a1,s3
    80005914:	855a                	mv	a0,s6
    80005916:	ffffc097          	auipc	ra,0xffffc
    8000591a:	b6c080e7          	jalr	-1172(ra) # 80001482 <uvmalloc>
    8000591e:	892a                	mv	s2,a0
    80005920:	e0a43423          	sd	a0,-504(s0)
    80005924:	e519                	bnez	a0,80005932 <exec+0x22c>
  if(pagetable)
    80005926:	e1343423          	sd	s3,-504(s0)
    8000592a:	4a01                	li	s4,0
    8000592c:	aaa5                	j	80005aa4 <exec+0x39e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000592e:	4901                	li	s2,0
    80005930:	bf45                	j	800058e0 <exec+0x1da>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005932:	75f9                	lui	a1,0xffffe
    80005934:	95aa                	add	a1,a1,a0
    80005936:	855a                	mv	a0,s6
    80005938:	ffffc097          	auipc	ra,0xffffc
    8000593c:	d74080e7          	jalr	-652(ra) # 800016ac <uvmclear>
  stackbase = sp - PGSIZE;
    80005940:	7bfd                	lui	s7,0xfffff
    80005942:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005944:	e0043783          	ld	a5,-512(s0)
    80005948:	6388                	ld	a0,0(a5)
    8000594a:	c52d                	beqz	a0,800059b4 <exec+0x2ae>
    8000594c:	e9040993          	add	s3,s0,-368
    80005950:	f9040c13          	add	s8,s0,-112
    80005954:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005956:	ffffb097          	auipc	ra,0xffffb
    8000595a:	552080e7          	jalr	1362(ra) # 80000ea8 <strlen>
    8000595e:	0015079b          	addw	a5,a0,1
    80005962:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005966:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    8000596a:	13796863          	bltu	s2,s7,80005a9a <exec+0x394>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000596e:	e0043d03          	ld	s10,-512(s0)
    80005972:	000d3a03          	ld	s4,0(s10)
    80005976:	8552                	mv	a0,s4
    80005978:	ffffb097          	auipc	ra,0xffffb
    8000597c:	530080e7          	jalr	1328(ra) # 80000ea8 <strlen>
    80005980:	0015069b          	addw	a3,a0,1
    80005984:	8652                	mv	a2,s4
    80005986:	85ca                	mv	a1,s2
    80005988:	855a                	mv	a0,s6
    8000598a:	ffffc097          	auipc	ra,0xffffc
    8000598e:	d54080e7          	jalr	-684(ra) # 800016de <copyout>
    80005992:	10054663          	bltz	a0,80005a9e <exec+0x398>
    ustack[argc] = sp;
    80005996:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000599a:	0485                	add	s1,s1,1
    8000599c:	008d0793          	add	a5,s10,8
    800059a0:	e0f43023          	sd	a5,-512(s0)
    800059a4:	008d3503          	ld	a0,8(s10)
    800059a8:	c909                	beqz	a0,800059ba <exec+0x2b4>
    if(argc >= MAXARG)
    800059aa:	09a1                	add	s3,s3,8
    800059ac:	fb8995e3          	bne	s3,s8,80005956 <exec+0x250>
  ip = 0;
    800059b0:	4a01                	li	s4,0
    800059b2:	a8cd                	j	80005aa4 <exec+0x39e>
  sp = sz;
    800059b4:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800059b8:	4481                	li	s1,0
  ustack[argc] = 0;
    800059ba:	00349793          	sll	a5,s1,0x3
    800059be:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd9ee8>
    800059c2:	97a2                	add	a5,a5,s0
    800059c4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800059c8:	00148693          	add	a3,s1,1
    800059cc:	068e                	sll	a3,a3,0x3
    800059ce:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800059d2:	ff097913          	and	s2,s2,-16
  sz = sz1;
    800059d6:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800059da:	f57966e3          	bltu	s2,s7,80005926 <exec+0x220>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800059de:	e9040613          	add	a2,s0,-368
    800059e2:	85ca                	mv	a1,s2
    800059e4:	855a                	mv	a0,s6
    800059e6:	ffffc097          	auipc	ra,0xffffc
    800059ea:	cf8080e7          	jalr	-776(ra) # 800016de <copyout>
    800059ee:	0e054863          	bltz	a0,80005ade <exec+0x3d8>
  p->trapframe->a1 = sp;
    800059f2:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800059f6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800059fa:	df843783          	ld	a5,-520(s0)
    800059fe:	0007c703          	lbu	a4,0(a5)
    80005a02:	cf11                	beqz	a4,80005a1e <exec+0x318>
    80005a04:	0785                	add	a5,a5,1
    if(*s == '/')
    80005a06:	02f00693          	li	a3,47
    80005a0a:	a039                	j	80005a18 <exec+0x312>
      last = s+1;
    80005a0c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005a10:	0785                	add	a5,a5,1
    80005a12:	fff7c703          	lbu	a4,-1(a5)
    80005a16:	c701                	beqz	a4,80005a1e <exec+0x318>
    if(*s == '/')
    80005a18:	fed71ce3          	bne	a4,a3,80005a10 <exec+0x30a>
    80005a1c:	bfc5                	j	80005a0c <exec+0x306>
  safestrcpy(p->name, last, sizeof(p->name));
    80005a1e:	4641                	li	a2,16
    80005a20:	df843583          	ld	a1,-520(s0)
    80005a24:	158a8513          	add	a0,s5,344
    80005a28:	ffffb097          	auipc	ra,0xffffb
    80005a2c:	44e080e7          	jalr	1102(ra) # 80000e76 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a30:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005a34:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005a38:	e0843783          	ld	a5,-504(s0)
    80005a3c:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a40:	058ab783          	ld	a5,88(s5)
    80005a44:	e6843703          	ld	a4,-408(s0)
    80005a48:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a4a:	058ab783          	ld	a5,88(s5)
    80005a4e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a52:	85e6                	mv	a1,s9
    80005a54:	ffffc097          	auipc	ra,0xffffc
    80005a58:	296080e7          	jalr	662(ra) # 80001cea <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005a5c:	0004851b          	sext.w	a0,s1
    80005a60:	79be                	ld	s3,488(sp)
    80005a62:	7a1e                	ld	s4,480(sp)
    80005a64:	6afe                	ld	s5,472(sp)
    80005a66:	6b5e                	ld	s6,464(sp)
    80005a68:	6bbe                	ld	s7,456(sp)
    80005a6a:	6c1e                	ld	s8,448(sp)
    80005a6c:	7cfa                	ld	s9,440(sp)
    80005a6e:	7d5a                	ld	s10,432(sp)
    80005a70:	b305                	j	80005790 <exec+0x8a>
    80005a72:	e1243423          	sd	s2,-504(s0)
    80005a76:	7dba                	ld	s11,424(sp)
    80005a78:	a035                	j	80005aa4 <exec+0x39e>
    80005a7a:	e1243423          	sd	s2,-504(s0)
    80005a7e:	7dba                	ld	s11,424(sp)
    80005a80:	a015                	j	80005aa4 <exec+0x39e>
    80005a82:	e1243423          	sd	s2,-504(s0)
    80005a86:	7dba                	ld	s11,424(sp)
    80005a88:	a831                	j	80005aa4 <exec+0x39e>
    80005a8a:	e1243423          	sd	s2,-504(s0)
    80005a8e:	7dba                	ld	s11,424(sp)
    80005a90:	a811                	j	80005aa4 <exec+0x39e>
    80005a92:	e1243423          	sd	s2,-504(s0)
    80005a96:	7dba                	ld	s11,424(sp)
    80005a98:	a031                	j	80005aa4 <exec+0x39e>
  ip = 0;
    80005a9a:	4a01                	li	s4,0
    80005a9c:	a021                	j	80005aa4 <exec+0x39e>
    80005a9e:	4a01                	li	s4,0
  if(pagetable)
    80005aa0:	a011                	j	80005aa4 <exec+0x39e>
    80005aa2:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80005aa4:	e0843583          	ld	a1,-504(s0)
    80005aa8:	855a                	mv	a0,s6
    80005aaa:	ffffc097          	auipc	ra,0xffffc
    80005aae:	240080e7          	jalr	576(ra) # 80001cea <proc_freepagetable>
  return -1;
    80005ab2:	557d                	li	a0,-1
  if(ip){
    80005ab4:	000a1b63          	bnez	s4,80005aca <exec+0x3c4>
    80005ab8:	79be                	ld	s3,488(sp)
    80005aba:	7a1e                	ld	s4,480(sp)
    80005abc:	6afe                	ld	s5,472(sp)
    80005abe:	6b5e                	ld	s6,464(sp)
    80005ac0:	6bbe                	ld	s7,456(sp)
    80005ac2:	6c1e                	ld	s8,448(sp)
    80005ac4:	7cfa                	ld	s9,440(sp)
    80005ac6:	7d5a                	ld	s10,432(sp)
    80005ac8:	b1e1                	j	80005790 <exec+0x8a>
    80005aca:	79be                	ld	s3,488(sp)
    80005acc:	6afe                	ld	s5,472(sp)
    80005ace:	6b5e                	ld	s6,464(sp)
    80005ad0:	6bbe                	ld	s7,456(sp)
    80005ad2:	6c1e                	ld	s8,448(sp)
    80005ad4:	7cfa                	ld	s9,440(sp)
    80005ad6:	7d5a                	ld	s10,432(sp)
    80005ad8:	b14d                	j	8000577a <exec+0x74>
    80005ada:	6b5e                	ld	s6,464(sp)
    80005adc:	b979                	j	8000577a <exec+0x74>
  sz = sz1;
    80005ade:	e0843983          	ld	s3,-504(s0)
    80005ae2:	b591                	j	80005926 <exec+0x220>

0000000080005ae4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005ae4:	7179                	add	sp,sp,-48
    80005ae6:	f406                	sd	ra,40(sp)
    80005ae8:	f022                	sd	s0,32(sp)
    80005aea:	ec26                	sd	s1,24(sp)
    80005aec:	e84a                	sd	s2,16(sp)
    80005aee:	1800                	add	s0,sp,48
    80005af0:	892e                	mv	s2,a1
    80005af2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005af4:	fdc40593          	add	a1,s0,-36
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	898080e7          	jalr	-1896(ra) # 80003390 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005b00:	fdc42703          	lw	a4,-36(s0)
    80005b04:	47bd                	li	a5,15
    80005b06:	02e7eb63          	bltu	a5,a4,80005b3c <argfd+0x58>
    80005b0a:	ffffc097          	auipc	ra,0xffffc
    80005b0e:	080080e7          	jalr	128(ra) # 80001b8a <myproc>
    80005b12:	fdc42703          	lw	a4,-36(s0)
    80005b16:	01a70793          	add	a5,a4,26
    80005b1a:	078e                	sll	a5,a5,0x3
    80005b1c:	953e                	add	a0,a0,a5
    80005b1e:	611c                	ld	a5,0(a0)
    80005b20:	c385                	beqz	a5,80005b40 <argfd+0x5c>
    return -1;
  if(pfd)
    80005b22:	00090463          	beqz	s2,80005b2a <argfd+0x46>
    *pfd = fd;
    80005b26:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005b2a:	4501                	li	a0,0
  if(pf)
    80005b2c:	c091                	beqz	s1,80005b30 <argfd+0x4c>
    *pf = f;
    80005b2e:	e09c                	sd	a5,0(s1)
}
    80005b30:	70a2                	ld	ra,40(sp)
    80005b32:	7402                	ld	s0,32(sp)
    80005b34:	64e2                	ld	s1,24(sp)
    80005b36:	6942                	ld	s2,16(sp)
    80005b38:	6145                	add	sp,sp,48
    80005b3a:	8082                	ret
    return -1;
    80005b3c:	557d                	li	a0,-1
    80005b3e:	bfcd                	j	80005b30 <argfd+0x4c>
    80005b40:	557d                	li	a0,-1
    80005b42:	b7fd                	j	80005b30 <argfd+0x4c>

0000000080005b44 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005b44:	1101                	add	sp,sp,-32
    80005b46:	ec06                	sd	ra,24(sp)
    80005b48:	e822                	sd	s0,16(sp)
    80005b4a:	e426                	sd	s1,8(sp)
    80005b4c:	1000                	add	s0,sp,32
    80005b4e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005b50:	ffffc097          	auipc	ra,0xffffc
    80005b54:	03a080e7          	jalr	58(ra) # 80001b8a <myproc>
    80005b58:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005b5a:	0d050793          	add	a5,a0,208
    80005b5e:	4501                	li	a0,0
    80005b60:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005b62:	6398                	ld	a4,0(a5)
    80005b64:	cb19                	beqz	a4,80005b7a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005b66:	2505                	addw	a0,a0,1
    80005b68:	07a1                	add	a5,a5,8
    80005b6a:	fed51ce3          	bne	a0,a3,80005b62 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005b6e:	557d                	li	a0,-1
}
    80005b70:	60e2                	ld	ra,24(sp)
    80005b72:	6442                	ld	s0,16(sp)
    80005b74:	64a2                	ld	s1,8(sp)
    80005b76:	6105                	add	sp,sp,32
    80005b78:	8082                	ret
      p->ofile[fd] = f;
    80005b7a:	01a50793          	add	a5,a0,26
    80005b7e:	078e                	sll	a5,a5,0x3
    80005b80:	963e                	add	a2,a2,a5
    80005b82:	e204                	sd	s1,0(a2)
      return fd;
    80005b84:	b7f5                	j	80005b70 <fdalloc+0x2c>

0000000080005b86 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005b86:	715d                	add	sp,sp,-80
    80005b88:	e486                	sd	ra,72(sp)
    80005b8a:	e0a2                	sd	s0,64(sp)
    80005b8c:	fc26                	sd	s1,56(sp)
    80005b8e:	f84a                	sd	s2,48(sp)
    80005b90:	f44e                	sd	s3,40(sp)
    80005b92:	ec56                	sd	s5,24(sp)
    80005b94:	e85a                	sd	s6,16(sp)
    80005b96:	0880                	add	s0,sp,80
    80005b98:	8b2e                	mv	s6,a1
    80005b9a:	89b2                	mv	s3,a2
    80005b9c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005b9e:	fb040593          	add	a1,s0,-80
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	de2080e7          	jalr	-542(ra) # 80004984 <nameiparent>
    80005baa:	84aa                	mv	s1,a0
    80005bac:	14050e63          	beqz	a0,80005d08 <create+0x182>
    return 0;

  ilock(dp);
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	5e8080e7          	jalr	1512(ra) # 80004198 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005bb8:	4601                	li	a2,0
    80005bba:	fb040593          	add	a1,s0,-80
    80005bbe:	8526                	mv	a0,s1
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	ae4080e7          	jalr	-1308(ra) # 800046a4 <dirlookup>
    80005bc8:	8aaa                	mv	s5,a0
    80005bca:	c539                	beqz	a0,80005c18 <create+0x92>
    iunlockput(dp);
    80005bcc:	8526                	mv	a0,s1
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	830080e7          	jalr	-2000(ra) # 800043fe <iunlockput>
    ilock(ip);
    80005bd6:	8556                	mv	a0,s5
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	5c0080e7          	jalr	1472(ra) # 80004198 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005be0:	4789                	li	a5,2
    80005be2:	02fb1463          	bne	s6,a5,80005c0a <create+0x84>
    80005be6:	044ad783          	lhu	a5,68(s5)
    80005bea:	37f9                	addw	a5,a5,-2
    80005bec:	17c2                	sll	a5,a5,0x30
    80005bee:	93c1                	srl	a5,a5,0x30
    80005bf0:	4705                	li	a4,1
    80005bf2:	00f76c63          	bltu	a4,a5,80005c0a <create+0x84>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005bf6:	8556                	mv	a0,s5
    80005bf8:	60a6                	ld	ra,72(sp)
    80005bfa:	6406                	ld	s0,64(sp)
    80005bfc:	74e2                	ld	s1,56(sp)
    80005bfe:	7942                	ld	s2,48(sp)
    80005c00:	79a2                	ld	s3,40(sp)
    80005c02:	6ae2                	ld	s5,24(sp)
    80005c04:	6b42                	ld	s6,16(sp)
    80005c06:	6161                	add	sp,sp,80
    80005c08:	8082                	ret
    iunlockput(ip);
    80005c0a:	8556                	mv	a0,s5
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	7f2080e7          	jalr	2034(ra) # 800043fe <iunlockput>
    return 0;
    80005c14:	4a81                	li	s5,0
    80005c16:	b7c5                	j	80005bf6 <create+0x70>
    80005c18:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80005c1a:	85da                	mv	a1,s6
    80005c1c:	4088                	lw	a0,0(s1)
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	3d6080e7          	jalr	982(ra) # 80003ff4 <ialloc>
    80005c26:	8a2a                	mv	s4,a0
    80005c28:	c531                	beqz	a0,80005c74 <create+0xee>
  ilock(ip);
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	56e080e7          	jalr	1390(ra) # 80004198 <ilock>
  ip->major = major;
    80005c32:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005c36:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005c3a:	4905                	li	s2,1
    80005c3c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005c40:	8552                	mv	a0,s4
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	48a080e7          	jalr	1162(ra) # 800040cc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005c4a:	032b0d63          	beq	s6,s2,80005c84 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005c4e:	004a2603          	lw	a2,4(s4)
    80005c52:	fb040593          	add	a1,s0,-80
    80005c56:	8526                	mv	a0,s1
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	c5c080e7          	jalr	-932(ra) # 800048b4 <dirlink>
    80005c60:	08054163          	bltz	a0,80005ce2 <create+0x15c>
  iunlockput(dp);
    80005c64:	8526                	mv	a0,s1
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	798080e7          	jalr	1944(ra) # 800043fe <iunlockput>
  return ip;
    80005c6e:	8ad2                	mv	s5,s4
    80005c70:	7a02                	ld	s4,32(sp)
    80005c72:	b751                	j	80005bf6 <create+0x70>
    iunlockput(dp);
    80005c74:	8526                	mv	a0,s1
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	788080e7          	jalr	1928(ra) # 800043fe <iunlockput>
    return 0;
    80005c7e:	8ad2                	mv	s5,s4
    80005c80:	7a02                	ld	s4,32(sp)
    80005c82:	bf95                	j	80005bf6 <create+0x70>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005c84:	004a2603          	lw	a2,4(s4)
    80005c88:	00004597          	auipc	a1,0x4
    80005c8c:	af058593          	add	a1,a1,-1296 # 80009778 <etext+0x778>
    80005c90:	8552                	mv	a0,s4
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	c22080e7          	jalr	-990(ra) # 800048b4 <dirlink>
    80005c9a:	04054463          	bltz	a0,80005ce2 <create+0x15c>
    80005c9e:	40d0                	lw	a2,4(s1)
    80005ca0:	00004597          	auipc	a1,0x4
    80005ca4:	ae058593          	add	a1,a1,-1312 # 80009780 <etext+0x780>
    80005ca8:	8552                	mv	a0,s4
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	c0a080e7          	jalr	-1014(ra) # 800048b4 <dirlink>
    80005cb2:	02054863          	bltz	a0,80005ce2 <create+0x15c>
  if(dirlink(dp, name, ip->inum) < 0)
    80005cb6:	004a2603          	lw	a2,4(s4)
    80005cba:	fb040593          	add	a1,s0,-80
    80005cbe:	8526                	mv	a0,s1
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	bf4080e7          	jalr	-1036(ra) # 800048b4 <dirlink>
    80005cc8:	00054d63          	bltz	a0,80005ce2 <create+0x15c>
    dp->nlink++;  // for ".."
    80005ccc:	04a4d783          	lhu	a5,74(s1)
    80005cd0:	2785                	addw	a5,a5,1
    80005cd2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cd6:	8526                	mv	a0,s1
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	3f4080e7          	jalr	1012(ra) # 800040cc <iupdate>
    80005ce0:	b751                	j	80005c64 <create+0xde>
  ip->nlink = 0;
    80005ce2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005ce6:	8552                	mv	a0,s4
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	3e4080e7          	jalr	996(ra) # 800040cc <iupdate>
  iunlockput(ip);
    80005cf0:	8552                	mv	a0,s4
    80005cf2:	ffffe097          	auipc	ra,0xffffe
    80005cf6:	70c080e7          	jalr	1804(ra) # 800043fe <iunlockput>
  iunlockput(dp);
    80005cfa:	8526                	mv	a0,s1
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	702080e7          	jalr	1794(ra) # 800043fe <iunlockput>
  return 0;
    80005d04:	7a02                	ld	s4,32(sp)
    80005d06:	bdc5                	j	80005bf6 <create+0x70>
    return 0;
    80005d08:	8aaa                	mv	s5,a0
    80005d0a:	b5f5                	j	80005bf6 <create+0x70>

0000000080005d0c <sys_dup>:
{
    80005d0c:	7179                	add	sp,sp,-48
    80005d0e:	f406                	sd	ra,40(sp)
    80005d10:	f022                	sd	s0,32(sp)
    80005d12:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005d14:	fd840613          	add	a2,s0,-40
    80005d18:	4581                	li	a1,0
    80005d1a:	4501                	li	a0,0
    80005d1c:	00000097          	auipc	ra,0x0
    80005d20:	dc8080e7          	jalr	-568(ra) # 80005ae4 <argfd>
    return -1;
    80005d24:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d26:	02054763          	bltz	a0,80005d54 <sys_dup+0x48>
    80005d2a:	ec26                	sd	s1,24(sp)
    80005d2c:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80005d2e:	fd843903          	ld	s2,-40(s0)
    80005d32:	854a                	mv	a0,s2
    80005d34:	00000097          	auipc	ra,0x0
    80005d38:	e10080e7          	jalr	-496(ra) # 80005b44 <fdalloc>
    80005d3c:	84aa                	mv	s1,a0
    return -1;
    80005d3e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005d40:	00054f63          	bltz	a0,80005d5e <sys_dup+0x52>
  filedup(f);
    80005d44:	854a                	mv	a0,s2
    80005d46:	fffff097          	auipc	ra,0xfffff
    80005d4a:	298080e7          	jalr	664(ra) # 80004fde <filedup>
  return fd;
    80005d4e:	87a6                	mv	a5,s1
    80005d50:	64e2                	ld	s1,24(sp)
    80005d52:	6942                	ld	s2,16(sp)
}
    80005d54:	853e                	mv	a0,a5
    80005d56:	70a2                	ld	ra,40(sp)
    80005d58:	7402                	ld	s0,32(sp)
    80005d5a:	6145                	add	sp,sp,48
    80005d5c:	8082                	ret
    80005d5e:	64e2                	ld	s1,24(sp)
    80005d60:	6942                	ld	s2,16(sp)
    80005d62:	bfcd                	j	80005d54 <sys_dup+0x48>

0000000080005d64 <sys_read>:
{
    80005d64:	7179                	add	sp,sp,-48
    80005d66:	f406                	sd	ra,40(sp)
    80005d68:	f022                	sd	s0,32(sp)
    80005d6a:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005d6c:	fd840593          	add	a1,s0,-40
    80005d70:	4505                	li	a0,1
    80005d72:	ffffd097          	auipc	ra,0xffffd
    80005d76:	63e080e7          	jalr	1598(ra) # 800033b0 <argaddr>
  argint(2, &n);
    80005d7a:	fe440593          	add	a1,s0,-28
    80005d7e:	4509                	li	a0,2
    80005d80:	ffffd097          	auipc	ra,0xffffd
    80005d84:	610080e7          	jalr	1552(ra) # 80003390 <argint>
  if(argfd(0, 0, &f) < 0)
    80005d88:	fe840613          	add	a2,s0,-24
    80005d8c:	4581                	li	a1,0
    80005d8e:	4501                	li	a0,0
    80005d90:	00000097          	auipc	ra,0x0
    80005d94:	d54080e7          	jalr	-684(ra) # 80005ae4 <argfd>
    80005d98:	87aa                	mv	a5,a0
    return -1;
    80005d9a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d9c:	0007cc63          	bltz	a5,80005db4 <sys_read+0x50>
  return fileread(f, p, n);
    80005da0:	fe442603          	lw	a2,-28(s0)
    80005da4:	fd843583          	ld	a1,-40(s0)
    80005da8:	fe843503          	ld	a0,-24(s0)
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	3d8080e7          	jalr	984(ra) # 80005184 <fileread>
}
    80005db4:	70a2                	ld	ra,40(sp)
    80005db6:	7402                	ld	s0,32(sp)
    80005db8:	6145                	add	sp,sp,48
    80005dba:	8082                	ret

0000000080005dbc <sys_write>:
{
    80005dbc:	7179                	add	sp,sp,-48
    80005dbe:	f406                	sd	ra,40(sp)
    80005dc0:	f022                	sd	s0,32(sp)
    80005dc2:	1800                	add	s0,sp,48
  argaddr(1, &p);
    80005dc4:	fd840593          	add	a1,s0,-40
    80005dc8:	4505                	li	a0,1
    80005dca:	ffffd097          	auipc	ra,0xffffd
    80005dce:	5e6080e7          	jalr	1510(ra) # 800033b0 <argaddr>
  argint(2, &n);
    80005dd2:	fe440593          	add	a1,s0,-28
    80005dd6:	4509                	li	a0,2
    80005dd8:	ffffd097          	auipc	ra,0xffffd
    80005ddc:	5b8080e7          	jalr	1464(ra) # 80003390 <argint>
  if(argfd(0, 0, &f) < 0)
    80005de0:	fe840613          	add	a2,s0,-24
    80005de4:	4581                	li	a1,0
    80005de6:	4501                	li	a0,0
    80005de8:	00000097          	auipc	ra,0x0
    80005dec:	cfc080e7          	jalr	-772(ra) # 80005ae4 <argfd>
    80005df0:	87aa                	mv	a5,a0
    return -1;
    80005df2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005df4:	0007cc63          	bltz	a5,80005e0c <sys_write+0x50>
  return filewrite(f, p, n);
    80005df8:	fe442603          	lw	a2,-28(s0)
    80005dfc:	fd843583          	ld	a1,-40(s0)
    80005e00:	fe843503          	ld	a0,-24(s0)
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	452080e7          	jalr	1106(ra) # 80005256 <filewrite>
}
    80005e0c:	70a2                	ld	ra,40(sp)
    80005e0e:	7402                	ld	s0,32(sp)
    80005e10:	6145                	add	sp,sp,48
    80005e12:	8082                	ret

0000000080005e14 <sys_close>:
{
    80005e14:	1101                	add	sp,sp,-32
    80005e16:	ec06                	sd	ra,24(sp)
    80005e18:	e822                	sd	s0,16(sp)
    80005e1a:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005e1c:	fe040613          	add	a2,s0,-32
    80005e20:	fec40593          	add	a1,s0,-20
    80005e24:	4501                	li	a0,0
    80005e26:	00000097          	auipc	ra,0x0
    80005e2a:	cbe080e7          	jalr	-834(ra) # 80005ae4 <argfd>
    return -1;
    80005e2e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005e30:	02054463          	bltz	a0,80005e58 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005e34:	ffffc097          	auipc	ra,0xffffc
    80005e38:	d56080e7          	jalr	-682(ra) # 80001b8a <myproc>
    80005e3c:	fec42783          	lw	a5,-20(s0)
    80005e40:	07e9                	add	a5,a5,26
    80005e42:	078e                	sll	a5,a5,0x3
    80005e44:	953e                	add	a0,a0,a5
    80005e46:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005e4a:	fe043503          	ld	a0,-32(s0)
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	1e2080e7          	jalr	482(ra) # 80005030 <fileclose>
  return 0;
    80005e56:	4781                	li	a5,0
}
    80005e58:	853e                	mv	a0,a5
    80005e5a:	60e2                	ld	ra,24(sp)
    80005e5c:	6442                	ld	s0,16(sp)
    80005e5e:	6105                	add	sp,sp,32
    80005e60:	8082                	ret

0000000080005e62 <sys_fstat>:
{
    80005e62:	1101                	add	sp,sp,-32
    80005e64:	ec06                	sd	ra,24(sp)
    80005e66:	e822                	sd	s0,16(sp)
    80005e68:	1000                	add	s0,sp,32
  argaddr(1, &st);
    80005e6a:	fe040593          	add	a1,s0,-32
    80005e6e:	4505                	li	a0,1
    80005e70:	ffffd097          	auipc	ra,0xffffd
    80005e74:	540080e7          	jalr	1344(ra) # 800033b0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005e78:	fe840613          	add	a2,s0,-24
    80005e7c:	4581                	li	a1,0
    80005e7e:	4501                	li	a0,0
    80005e80:	00000097          	auipc	ra,0x0
    80005e84:	c64080e7          	jalr	-924(ra) # 80005ae4 <argfd>
    80005e88:	87aa                	mv	a5,a0
    return -1;
    80005e8a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e8c:	0007ca63          	bltz	a5,80005ea0 <sys_fstat+0x3e>
  return filestat(f, st);
    80005e90:	fe043583          	ld	a1,-32(s0)
    80005e94:	fe843503          	ld	a0,-24(s0)
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	27a080e7          	jalr	634(ra) # 80005112 <filestat>
}
    80005ea0:	60e2                	ld	ra,24(sp)
    80005ea2:	6442                	ld	s0,16(sp)
    80005ea4:	6105                	add	sp,sp,32
    80005ea6:	8082                	ret

0000000080005ea8 <sys_link>:
{
    80005ea8:	7169                	add	sp,sp,-304
    80005eaa:	f606                	sd	ra,296(sp)
    80005eac:	f222                	sd	s0,288(sp)
    80005eae:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005eb0:	08000613          	li	a2,128
    80005eb4:	ed040593          	add	a1,s0,-304
    80005eb8:	4501                	li	a0,0
    80005eba:	ffffd097          	auipc	ra,0xffffd
    80005ebe:	516080e7          	jalr	1302(ra) # 800033d0 <argstr>
    return -1;
    80005ec2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ec4:	12054663          	bltz	a0,80005ff0 <sys_link+0x148>
    80005ec8:	08000613          	li	a2,128
    80005ecc:	f5040593          	add	a1,s0,-176
    80005ed0:	4505                	li	a0,1
    80005ed2:	ffffd097          	auipc	ra,0xffffd
    80005ed6:	4fe080e7          	jalr	1278(ra) # 800033d0 <argstr>
    return -1;
    80005eda:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005edc:	10054a63          	bltz	a0,80005ff0 <sys_link+0x148>
    80005ee0:	ee26                	sd	s1,280(sp)
  begin_op();
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	c84080e7          	jalr	-892(ra) # 80004b66 <begin_op>
  if((ip = namei(old)) == 0){
    80005eea:	ed040513          	add	a0,s0,-304
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	a78080e7          	jalr	-1416(ra) # 80004966 <namei>
    80005ef6:	84aa                	mv	s1,a0
    80005ef8:	c949                	beqz	a0,80005f8a <sys_link+0xe2>
  ilock(ip);
    80005efa:	ffffe097          	auipc	ra,0xffffe
    80005efe:	29e080e7          	jalr	670(ra) # 80004198 <ilock>
  if(ip->type == T_DIR){
    80005f02:	04449703          	lh	a4,68(s1)
    80005f06:	4785                	li	a5,1
    80005f08:	08f70863          	beq	a4,a5,80005f98 <sys_link+0xf0>
    80005f0c:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005f0e:	04a4d783          	lhu	a5,74(s1)
    80005f12:	2785                	addw	a5,a5,1
    80005f14:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f18:	8526                	mv	a0,s1
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	1b2080e7          	jalr	434(ra) # 800040cc <iupdate>
  iunlock(ip);
    80005f22:	8526                	mv	a0,s1
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	33a080e7          	jalr	826(ra) # 8000425e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005f2c:	fd040593          	add	a1,s0,-48
    80005f30:	f5040513          	add	a0,s0,-176
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	a50080e7          	jalr	-1456(ra) # 80004984 <nameiparent>
    80005f3c:	892a                	mv	s2,a0
    80005f3e:	cd35                	beqz	a0,80005fba <sys_link+0x112>
  ilock(dp);
    80005f40:	ffffe097          	auipc	ra,0xffffe
    80005f44:	258080e7          	jalr	600(ra) # 80004198 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005f48:	00092703          	lw	a4,0(s2)
    80005f4c:	409c                	lw	a5,0(s1)
    80005f4e:	06f71163          	bne	a4,a5,80005fb0 <sys_link+0x108>
    80005f52:	40d0                	lw	a2,4(s1)
    80005f54:	fd040593          	add	a1,s0,-48
    80005f58:	854a                	mv	a0,s2
    80005f5a:	fffff097          	auipc	ra,0xfffff
    80005f5e:	95a080e7          	jalr	-1702(ra) # 800048b4 <dirlink>
    80005f62:	04054763          	bltz	a0,80005fb0 <sys_link+0x108>
  iunlockput(dp);
    80005f66:	854a                	mv	a0,s2
    80005f68:	ffffe097          	auipc	ra,0xffffe
    80005f6c:	496080e7          	jalr	1174(ra) # 800043fe <iunlockput>
  iput(ip);
    80005f70:	8526                	mv	a0,s1
    80005f72:	ffffe097          	auipc	ra,0xffffe
    80005f76:	3e4080e7          	jalr	996(ra) # 80004356 <iput>
  end_op();
    80005f7a:	fffff097          	auipc	ra,0xfffff
    80005f7e:	c66080e7          	jalr	-922(ra) # 80004be0 <end_op>
  return 0;
    80005f82:	4781                	li	a5,0
    80005f84:	64f2                	ld	s1,280(sp)
    80005f86:	6952                	ld	s2,272(sp)
    80005f88:	a0a5                	j	80005ff0 <sys_link+0x148>
    end_op();
    80005f8a:	fffff097          	auipc	ra,0xfffff
    80005f8e:	c56080e7          	jalr	-938(ra) # 80004be0 <end_op>
    return -1;
    80005f92:	57fd                	li	a5,-1
    80005f94:	64f2                	ld	s1,280(sp)
    80005f96:	a8a9                	j	80005ff0 <sys_link+0x148>
    iunlockput(ip);
    80005f98:	8526                	mv	a0,s1
    80005f9a:	ffffe097          	auipc	ra,0xffffe
    80005f9e:	464080e7          	jalr	1124(ra) # 800043fe <iunlockput>
    end_op();
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	c3e080e7          	jalr	-962(ra) # 80004be0 <end_op>
    return -1;
    80005faa:	57fd                	li	a5,-1
    80005fac:	64f2                	ld	s1,280(sp)
    80005fae:	a089                	j	80005ff0 <sys_link+0x148>
    iunlockput(dp);
    80005fb0:	854a                	mv	a0,s2
    80005fb2:	ffffe097          	auipc	ra,0xffffe
    80005fb6:	44c080e7          	jalr	1100(ra) # 800043fe <iunlockput>
  ilock(ip);
    80005fba:	8526                	mv	a0,s1
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	1dc080e7          	jalr	476(ra) # 80004198 <ilock>
  ip->nlink--;
    80005fc4:	04a4d783          	lhu	a5,74(s1)
    80005fc8:	37fd                	addw	a5,a5,-1
    80005fca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005fce:	8526                	mv	a0,s1
    80005fd0:	ffffe097          	auipc	ra,0xffffe
    80005fd4:	0fc080e7          	jalr	252(ra) # 800040cc <iupdate>
  iunlockput(ip);
    80005fd8:	8526                	mv	a0,s1
    80005fda:	ffffe097          	auipc	ra,0xffffe
    80005fde:	424080e7          	jalr	1060(ra) # 800043fe <iunlockput>
  end_op();
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	bfe080e7          	jalr	-1026(ra) # 80004be0 <end_op>
  return -1;
    80005fea:	57fd                	li	a5,-1
    80005fec:	64f2                	ld	s1,280(sp)
    80005fee:	6952                	ld	s2,272(sp)
}
    80005ff0:	853e                	mv	a0,a5
    80005ff2:	70b2                	ld	ra,296(sp)
    80005ff4:	7412                	ld	s0,288(sp)
    80005ff6:	6155                	add	sp,sp,304
    80005ff8:	8082                	ret

0000000080005ffa <sys_unlink>:
{
    80005ffa:	7151                	add	sp,sp,-240
    80005ffc:	f586                	sd	ra,232(sp)
    80005ffe:	f1a2                	sd	s0,224(sp)
    80006000:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006002:	08000613          	li	a2,128
    80006006:	f3040593          	add	a1,s0,-208
    8000600a:	4501                	li	a0,0
    8000600c:	ffffd097          	auipc	ra,0xffffd
    80006010:	3c4080e7          	jalr	964(ra) # 800033d0 <argstr>
    80006014:	1a054a63          	bltz	a0,800061c8 <sys_unlink+0x1ce>
    80006018:	eda6                	sd	s1,216(sp)
  begin_op();
    8000601a:	fffff097          	auipc	ra,0xfffff
    8000601e:	b4c080e7          	jalr	-1204(ra) # 80004b66 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006022:	fb040593          	add	a1,s0,-80
    80006026:	f3040513          	add	a0,s0,-208
    8000602a:	fffff097          	auipc	ra,0xfffff
    8000602e:	95a080e7          	jalr	-1702(ra) # 80004984 <nameiparent>
    80006032:	84aa                	mv	s1,a0
    80006034:	cd71                	beqz	a0,80006110 <sys_unlink+0x116>
  ilock(dp);
    80006036:	ffffe097          	auipc	ra,0xffffe
    8000603a:	162080e7          	jalr	354(ra) # 80004198 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000603e:	00003597          	auipc	a1,0x3
    80006042:	73a58593          	add	a1,a1,1850 # 80009778 <etext+0x778>
    80006046:	fb040513          	add	a0,s0,-80
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	640080e7          	jalr	1600(ra) # 8000468a <namecmp>
    80006052:	14050c63          	beqz	a0,800061aa <sys_unlink+0x1b0>
    80006056:	00003597          	auipc	a1,0x3
    8000605a:	72a58593          	add	a1,a1,1834 # 80009780 <etext+0x780>
    8000605e:	fb040513          	add	a0,s0,-80
    80006062:	ffffe097          	auipc	ra,0xffffe
    80006066:	628080e7          	jalr	1576(ra) # 8000468a <namecmp>
    8000606a:	14050063          	beqz	a0,800061aa <sys_unlink+0x1b0>
    8000606e:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006070:	f2c40613          	add	a2,s0,-212
    80006074:	fb040593          	add	a1,s0,-80
    80006078:	8526                	mv	a0,s1
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	62a080e7          	jalr	1578(ra) # 800046a4 <dirlookup>
    80006082:	892a                	mv	s2,a0
    80006084:	12050263          	beqz	a0,800061a8 <sys_unlink+0x1ae>
  ilock(ip);
    80006088:	ffffe097          	auipc	ra,0xffffe
    8000608c:	110080e7          	jalr	272(ra) # 80004198 <ilock>
  if(ip->nlink < 1)
    80006090:	04a91783          	lh	a5,74(s2)
    80006094:	08f05563          	blez	a5,8000611e <sys_unlink+0x124>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006098:	04491703          	lh	a4,68(s2)
    8000609c:	4785                	li	a5,1
    8000609e:	08f70963          	beq	a4,a5,80006130 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    800060a2:	4641                	li	a2,16
    800060a4:	4581                	li	a1,0
    800060a6:	fc040513          	add	a0,s0,-64
    800060aa:	ffffb097          	auipc	ra,0xffffb
    800060ae:	c8a080e7          	jalr	-886(ra) # 80000d34 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060b2:	4741                	li	a4,16
    800060b4:	f2c42683          	lw	a3,-212(s0)
    800060b8:	fc040613          	add	a2,s0,-64
    800060bc:	4581                	li	a1,0
    800060be:	8526                	mv	a0,s1
    800060c0:	ffffe097          	auipc	ra,0xffffe
    800060c4:	4a0080e7          	jalr	1184(ra) # 80004560 <writei>
    800060c8:	47c1                	li	a5,16
    800060ca:	0af51b63          	bne	a0,a5,80006180 <sys_unlink+0x186>
  if(ip->type == T_DIR){
    800060ce:	04491703          	lh	a4,68(s2)
    800060d2:	4785                	li	a5,1
    800060d4:	0af70f63          	beq	a4,a5,80006192 <sys_unlink+0x198>
  iunlockput(dp);
    800060d8:	8526                	mv	a0,s1
    800060da:	ffffe097          	auipc	ra,0xffffe
    800060de:	324080e7          	jalr	804(ra) # 800043fe <iunlockput>
  ip->nlink--;
    800060e2:	04a95783          	lhu	a5,74(s2)
    800060e6:	37fd                	addw	a5,a5,-1
    800060e8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800060ec:	854a                	mv	a0,s2
    800060ee:	ffffe097          	auipc	ra,0xffffe
    800060f2:	fde080e7          	jalr	-34(ra) # 800040cc <iupdate>
  iunlockput(ip);
    800060f6:	854a                	mv	a0,s2
    800060f8:	ffffe097          	auipc	ra,0xffffe
    800060fc:	306080e7          	jalr	774(ra) # 800043fe <iunlockput>
  end_op();
    80006100:	fffff097          	auipc	ra,0xfffff
    80006104:	ae0080e7          	jalr	-1312(ra) # 80004be0 <end_op>
  return 0;
    80006108:	4501                	li	a0,0
    8000610a:	64ee                	ld	s1,216(sp)
    8000610c:	694e                	ld	s2,208(sp)
    8000610e:	a84d                	j	800061c0 <sys_unlink+0x1c6>
    end_op();
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	ad0080e7          	jalr	-1328(ra) # 80004be0 <end_op>
    return -1;
    80006118:	557d                	li	a0,-1
    8000611a:	64ee                	ld	s1,216(sp)
    8000611c:	a055                	j	800061c0 <sys_unlink+0x1c6>
    8000611e:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80006120:	00003517          	auipc	a0,0x3
    80006124:	66850513          	add	a0,a0,1640 # 80009788 <etext+0x788>
    80006128:	ffffa097          	auipc	ra,0xffffa
    8000612c:	438080e7          	jalr	1080(ra) # 80000560 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006130:	04c92703          	lw	a4,76(s2)
    80006134:	02000793          	li	a5,32
    80006138:	f6e7f5e3          	bgeu	a5,a4,800060a2 <sys_unlink+0xa8>
    8000613c:	e5ce                	sd	s3,200(sp)
    8000613e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006142:	4741                	li	a4,16
    80006144:	86ce                	mv	a3,s3
    80006146:	f1840613          	add	a2,s0,-232
    8000614a:	4581                	li	a1,0
    8000614c:	854a                	mv	a0,s2
    8000614e:	ffffe097          	auipc	ra,0xffffe
    80006152:	302080e7          	jalr	770(ra) # 80004450 <readi>
    80006156:	47c1                	li	a5,16
    80006158:	00f51c63          	bne	a0,a5,80006170 <sys_unlink+0x176>
    if(de.inum != 0)
    8000615c:	f1845783          	lhu	a5,-232(s0)
    80006160:	e7b5                	bnez	a5,800061cc <sys_unlink+0x1d2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006162:	29c1                	addw	s3,s3,16
    80006164:	04c92783          	lw	a5,76(s2)
    80006168:	fcf9ede3          	bltu	s3,a5,80006142 <sys_unlink+0x148>
    8000616c:	69ae                	ld	s3,200(sp)
    8000616e:	bf15                	j	800060a2 <sys_unlink+0xa8>
      panic("isdirempty: readi");
    80006170:	00003517          	auipc	a0,0x3
    80006174:	63050513          	add	a0,a0,1584 # 800097a0 <etext+0x7a0>
    80006178:	ffffa097          	auipc	ra,0xffffa
    8000617c:	3e8080e7          	jalr	1000(ra) # 80000560 <panic>
    80006180:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80006182:	00003517          	auipc	a0,0x3
    80006186:	63650513          	add	a0,a0,1590 # 800097b8 <etext+0x7b8>
    8000618a:	ffffa097          	auipc	ra,0xffffa
    8000618e:	3d6080e7          	jalr	982(ra) # 80000560 <panic>
    dp->nlink--;
    80006192:	04a4d783          	lhu	a5,74(s1)
    80006196:	37fd                	addw	a5,a5,-1
    80006198:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000619c:	8526                	mv	a0,s1
    8000619e:	ffffe097          	auipc	ra,0xffffe
    800061a2:	f2e080e7          	jalr	-210(ra) # 800040cc <iupdate>
    800061a6:	bf0d                	j	800060d8 <sys_unlink+0xde>
    800061a8:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    800061aa:	8526                	mv	a0,s1
    800061ac:	ffffe097          	auipc	ra,0xffffe
    800061b0:	252080e7          	jalr	594(ra) # 800043fe <iunlockput>
  end_op();
    800061b4:	fffff097          	auipc	ra,0xfffff
    800061b8:	a2c080e7          	jalr	-1492(ra) # 80004be0 <end_op>
  return -1;
    800061bc:	557d                	li	a0,-1
    800061be:	64ee                	ld	s1,216(sp)
}
    800061c0:	70ae                	ld	ra,232(sp)
    800061c2:	740e                	ld	s0,224(sp)
    800061c4:	616d                	add	sp,sp,240
    800061c6:	8082                	ret
    return -1;
    800061c8:	557d                	li	a0,-1
    800061ca:	bfdd                	j	800061c0 <sys_unlink+0x1c6>
    iunlockput(ip);
    800061cc:	854a                	mv	a0,s2
    800061ce:	ffffe097          	auipc	ra,0xffffe
    800061d2:	230080e7          	jalr	560(ra) # 800043fe <iunlockput>
    goto bad;
    800061d6:	694e                	ld	s2,208(sp)
    800061d8:	69ae                	ld	s3,200(sp)
    800061da:	bfc1                	j	800061aa <sys_unlink+0x1b0>

00000000800061dc <sys_open>:

uint64
sys_open(void)
{
    800061dc:	7131                	add	sp,sp,-192
    800061de:	fd06                	sd	ra,184(sp)
    800061e0:	f922                	sd	s0,176(sp)
    800061e2:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800061e4:	f4c40593          	add	a1,s0,-180
    800061e8:	4505                	li	a0,1
    800061ea:	ffffd097          	auipc	ra,0xffffd
    800061ee:	1a6080e7          	jalr	422(ra) # 80003390 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800061f2:	08000613          	li	a2,128
    800061f6:	f5040593          	add	a1,s0,-176
    800061fa:	4501                	li	a0,0
    800061fc:	ffffd097          	auipc	ra,0xffffd
    80006200:	1d4080e7          	jalr	468(ra) # 800033d0 <argstr>
    80006204:	87aa                	mv	a5,a0
    return -1;
    80006206:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006208:	0a07ce63          	bltz	a5,800062c4 <sys_open+0xe8>
    8000620c:	f526                	sd	s1,168(sp)

  begin_op();
    8000620e:	fffff097          	auipc	ra,0xfffff
    80006212:	958080e7          	jalr	-1704(ra) # 80004b66 <begin_op>

  if(omode & O_CREATE){
    80006216:	f4c42783          	lw	a5,-180(s0)
    8000621a:	2007f793          	and	a5,a5,512
    8000621e:	cfd5                	beqz	a5,800062da <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006220:	4681                	li	a3,0
    80006222:	4601                	li	a2,0
    80006224:	4589                	li	a1,2
    80006226:	f5040513          	add	a0,s0,-176
    8000622a:	00000097          	auipc	ra,0x0
    8000622e:	95c080e7          	jalr	-1700(ra) # 80005b86 <create>
    80006232:	84aa                	mv	s1,a0
    if(ip == 0){
    80006234:	cd41                	beqz	a0,800062cc <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006236:	04449703          	lh	a4,68(s1)
    8000623a:	478d                	li	a5,3
    8000623c:	00f71763          	bne	a4,a5,8000624a <sys_open+0x6e>
    80006240:	0464d703          	lhu	a4,70(s1)
    80006244:	47a5                	li	a5,9
    80006246:	0ee7e163          	bltu	a5,a4,80006328 <sys_open+0x14c>
    8000624a:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000624c:	fffff097          	auipc	ra,0xfffff
    80006250:	d28080e7          	jalr	-728(ra) # 80004f74 <filealloc>
    80006254:	892a                	mv	s2,a0
    80006256:	c97d                	beqz	a0,8000634c <sys_open+0x170>
    80006258:	ed4e                	sd	s3,152(sp)
    8000625a:	00000097          	auipc	ra,0x0
    8000625e:	8ea080e7          	jalr	-1814(ra) # 80005b44 <fdalloc>
    80006262:	89aa                	mv	s3,a0
    80006264:	0c054e63          	bltz	a0,80006340 <sys_open+0x164>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006268:	04449703          	lh	a4,68(s1)
    8000626c:	478d                	li	a5,3
    8000626e:	0ef70c63          	beq	a4,a5,80006366 <sys_open+0x18a>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006272:	4789                	li	a5,2
    80006274:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80006278:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000627c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80006280:	f4c42783          	lw	a5,-180(s0)
    80006284:	0017c713          	xor	a4,a5,1
    80006288:	8b05                	and	a4,a4,1
    8000628a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000628e:	0037f713          	and	a4,a5,3
    80006292:	00e03733          	snez	a4,a4
    80006296:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000629a:	4007f793          	and	a5,a5,1024
    8000629e:	c791                	beqz	a5,800062aa <sys_open+0xce>
    800062a0:	04449703          	lh	a4,68(s1)
    800062a4:	4789                	li	a5,2
    800062a6:	0cf70763          	beq	a4,a5,80006374 <sys_open+0x198>
    itrunc(ip);
  }

  iunlock(ip);
    800062aa:	8526                	mv	a0,s1
    800062ac:	ffffe097          	auipc	ra,0xffffe
    800062b0:	fb2080e7          	jalr	-78(ra) # 8000425e <iunlock>
  end_op();
    800062b4:	fffff097          	auipc	ra,0xfffff
    800062b8:	92c080e7          	jalr	-1748(ra) # 80004be0 <end_op>

  return fd;
    800062bc:	854e                	mv	a0,s3
    800062be:	74aa                	ld	s1,168(sp)
    800062c0:	790a                	ld	s2,160(sp)
    800062c2:	69ea                	ld	s3,152(sp)
}
    800062c4:	70ea                	ld	ra,184(sp)
    800062c6:	744a                	ld	s0,176(sp)
    800062c8:	6129                	add	sp,sp,192
    800062ca:	8082                	ret
      end_op();
    800062cc:	fffff097          	auipc	ra,0xfffff
    800062d0:	914080e7          	jalr	-1772(ra) # 80004be0 <end_op>
      return -1;
    800062d4:	557d                	li	a0,-1
    800062d6:	74aa                	ld	s1,168(sp)
    800062d8:	b7f5                	j	800062c4 <sys_open+0xe8>
    if((ip = namei(path)) == 0){
    800062da:	f5040513          	add	a0,s0,-176
    800062de:	ffffe097          	auipc	ra,0xffffe
    800062e2:	688080e7          	jalr	1672(ra) # 80004966 <namei>
    800062e6:	84aa                	mv	s1,a0
    800062e8:	c90d                	beqz	a0,8000631a <sys_open+0x13e>
    ilock(ip);
    800062ea:	ffffe097          	auipc	ra,0xffffe
    800062ee:	eae080e7          	jalr	-338(ra) # 80004198 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800062f2:	04449703          	lh	a4,68(s1)
    800062f6:	4785                	li	a5,1
    800062f8:	f2f71fe3          	bne	a4,a5,80006236 <sys_open+0x5a>
    800062fc:	f4c42783          	lw	a5,-180(s0)
    80006300:	d7a9                	beqz	a5,8000624a <sys_open+0x6e>
      iunlockput(ip);
    80006302:	8526                	mv	a0,s1
    80006304:	ffffe097          	auipc	ra,0xffffe
    80006308:	0fa080e7          	jalr	250(ra) # 800043fe <iunlockput>
      end_op();
    8000630c:	fffff097          	auipc	ra,0xfffff
    80006310:	8d4080e7          	jalr	-1836(ra) # 80004be0 <end_op>
      return -1;
    80006314:	557d                	li	a0,-1
    80006316:	74aa                	ld	s1,168(sp)
    80006318:	b775                	j	800062c4 <sys_open+0xe8>
      end_op();
    8000631a:	fffff097          	auipc	ra,0xfffff
    8000631e:	8c6080e7          	jalr	-1850(ra) # 80004be0 <end_op>
      return -1;
    80006322:	557d                	li	a0,-1
    80006324:	74aa                	ld	s1,168(sp)
    80006326:	bf79                	j	800062c4 <sys_open+0xe8>
    iunlockput(ip);
    80006328:	8526                	mv	a0,s1
    8000632a:	ffffe097          	auipc	ra,0xffffe
    8000632e:	0d4080e7          	jalr	212(ra) # 800043fe <iunlockput>
    end_op();
    80006332:	fffff097          	auipc	ra,0xfffff
    80006336:	8ae080e7          	jalr	-1874(ra) # 80004be0 <end_op>
    return -1;
    8000633a:	557d                	li	a0,-1
    8000633c:	74aa                	ld	s1,168(sp)
    8000633e:	b759                	j	800062c4 <sys_open+0xe8>
      fileclose(f);
    80006340:	854a                	mv	a0,s2
    80006342:	fffff097          	auipc	ra,0xfffff
    80006346:	cee080e7          	jalr	-786(ra) # 80005030 <fileclose>
    8000634a:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    8000634c:	8526                	mv	a0,s1
    8000634e:	ffffe097          	auipc	ra,0xffffe
    80006352:	0b0080e7          	jalr	176(ra) # 800043fe <iunlockput>
    end_op();
    80006356:	fffff097          	auipc	ra,0xfffff
    8000635a:	88a080e7          	jalr	-1910(ra) # 80004be0 <end_op>
    return -1;
    8000635e:	557d                	li	a0,-1
    80006360:	74aa                	ld	s1,168(sp)
    80006362:	790a                	ld	s2,160(sp)
    80006364:	b785                	j	800062c4 <sys_open+0xe8>
    f->type = FD_DEVICE;
    80006366:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    8000636a:	04649783          	lh	a5,70(s1)
    8000636e:	02f91223          	sh	a5,36(s2)
    80006372:	b729                	j	8000627c <sys_open+0xa0>
    itrunc(ip);
    80006374:	8526                	mv	a0,s1
    80006376:	ffffe097          	auipc	ra,0xffffe
    8000637a:	f34080e7          	jalr	-204(ra) # 800042aa <itrunc>
    8000637e:	b735                	j	800062aa <sys_open+0xce>

0000000080006380 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006380:	7175                	add	sp,sp,-144
    80006382:	e506                	sd	ra,136(sp)
    80006384:	e122                	sd	s0,128(sp)
    80006386:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006388:	ffffe097          	auipc	ra,0xffffe
    8000638c:	7de080e7          	jalr	2014(ra) # 80004b66 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006390:	08000613          	li	a2,128
    80006394:	f7040593          	add	a1,s0,-144
    80006398:	4501                	li	a0,0
    8000639a:	ffffd097          	auipc	ra,0xffffd
    8000639e:	036080e7          	jalr	54(ra) # 800033d0 <argstr>
    800063a2:	02054963          	bltz	a0,800063d4 <sys_mkdir+0x54>
    800063a6:	4681                	li	a3,0
    800063a8:	4601                	li	a2,0
    800063aa:	4585                	li	a1,1
    800063ac:	f7040513          	add	a0,s0,-144
    800063b0:	fffff097          	auipc	ra,0xfffff
    800063b4:	7d6080e7          	jalr	2006(ra) # 80005b86 <create>
    800063b8:	cd11                	beqz	a0,800063d4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800063ba:	ffffe097          	auipc	ra,0xffffe
    800063be:	044080e7          	jalr	68(ra) # 800043fe <iunlockput>
  end_op();
    800063c2:	fffff097          	auipc	ra,0xfffff
    800063c6:	81e080e7          	jalr	-2018(ra) # 80004be0 <end_op>
  return 0;
    800063ca:	4501                	li	a0,0
}
    800063cc:	60aa                	ld	ra,136(sp)
    800063ce:	640a                	ld	s0,128(sp)
    800063d0:	6149                	add	sp,sp,144
    800063d2:	8082                	ret
    end_op();
    800063d4:	fffff097          	auipc	ra,0xfffff
    800063d8:	80c080e7          	jalr	-2036(ra) # 80004be0 <end_op>
    return -1;
    800063dc:	557d                	li	a0,-1
    800063de:	b7fd                	j	800063cc <sys_mkdir+0x4c>

00000000800063e0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800063e0:	7135                	add	sp,sp,-160
    800063e2:	ed06                	sd	ra,152(sp)
    800063e4:	e922                	sd	s0,144(sp)
    800063e6:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800063e8:	ffffe097          	auipc	ra,0xffffe
    800063ec:	77e080e7          	jalr	1918(ra) # 80004b66 <begin_op>
  argint(1, &major);
    800063f0:	f6c40593          	add	a1,s0,-148
    800063f4:	4505                	li	a0,1
    800063f6:	ffffd097          	auipc	ra,0xffffd
    800063fa:	f9a080e7          	jalr	-102(ra) # 80003390 <argint>
  argint(2, &minor);
    800063fe:	f6840593          	add	a1,s0,-152
    80006402:	4509                	li	a0,2
    80006404:	ffffd097          	auipc	ra,0xffffd
    80006408:	f8c080e7          	jalr	-116(ra) # 80003390 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000640c:	08000613          	li	a2,128
    80006410:	f7040593          	add	a1,s0,-144
    80006414:	4501                	li	a0,0
    80006416:	ffffd097          	auipc	ra,0xffffd
    8000641a:	fba080e7          	jalr	-70(ra) # 800033d0 <argstr>
    8000641e:	02054b63          	bltz	a0,80006454 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006422:	f6841683          	lh	a3,-152(s0)
    80006426:	f6c41603          	lh	a2,-148(s0)
    8000642a:	458d                	li	a1,3
    8000642c:	f7040513          	add	a0,s0,-144
    80006430:	fffff097          	auipc	ra,0xfffff
    80006434:	756080e7          	jalr	1878(ra) # 80005b86 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006438:	cd11                	beqz	a0,80006454 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000643a:	ffffe097          	auipc	ra,0xffffe
    8000643e:	fc4080e7          	jalr	-60(ra) # 800043fe <iunlockput>
  end_op();
    80006442:	ffffe097          	auipc	ra,0xffffe
    80006446:	79e080e7          	jalr	1950(ra) # 80004be0 <end_op>
  return 0;
    8000644a:	4501                	li	a0,0
}
    8000644c:	60ea                	ld	ra,152(sp)
    8000644e:	644a                	ld	s0,144(sp)
    80006450:	610d                	add	sp,sp,160
    80006452:	8082                	ret
    end_op();
    80006454:	ffffe097          	auipc	ra,0xffffe
    80006458:	78c080e7          	jalr	1932(ra) # 80004be0 <end_op>
    return -1;
    8000645c:	557d                	li	a0,-1
    8000645e:	b7fd                	j	8000644c <sys_mknod+0x6c>

0000000080006460 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006460:	7135                	add	sp,sp,-160
    80006462:	ed06                	sd	ra,152(sp)
    80006464:	e922                	sd	s0,144(sp)
    80006466:	e14a                	sd	s2,128(sp)
    80006468:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000646a:	ffffb097          	auipc	ra,0xffffb
    8000646e:	720080e7          	jalr	1824(ra) # 80001b8a <myproc>
    80006472:	892a                	mv	s2,a0
  
  begin_op();
    80006474:	ffffe097          	auipc	ra,0xffffe
    80006478:	6f2080e7          	jalr	1778(ra) # 80004b66 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000647c:	08000613          	li	a2,128
    80006480:	f6040593          	add	a1,s0,-160
    80006484:	4501                	li	a0,0
    80006486:	ffffd097          	auipc	ra,0xffffd
    8000648a:	f4a080e7          	jalr	-182(ra) # 800033d0 <argstr>
    8000648e:	04054d63          	bltz	a0,800064e8 <sys_chdir+0x88>
    80006492:	e526                	sd	s1,136(sp)
    80006494:	f6040513          	add	a0,s0,-160
    80006498:	ffffe097          	auipc	ra,0xffffe
    8000649c:	4ce080e7          	jalr	1230(ra) # 80004966 <namei>
    800064a0:	84aa                	mv	s1,a0
    800064a2:	c131                	beqz	a0,800064e6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800064a4:	ffffe097          	auipc	ra,0xffffe
    800064a8:	cf4080e7          	jalr	-780(ra) # 80004198 <ilock>
  if(ip->type != T_DIR){
    800064ac:	04449703          	lh	a4,68(s1)
    800064b0:	4785                	li	a5,1
    800064b2:	04f71163          	bne	a4,a5,800064f4 <sys_chdir+0x94>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800064b6:	8526                	mv	a0,s1
    800064b8:	ffffe097          	auipc	ra,0xffffe
    800064bc:	da6080e7          	jalr	-602(ra) # 8000425e <iunlock>
  iput(p->cwd);
    800064c0:	15093503          	ld	a0,336(s2)
    800064c4:	ffffe097          	auipc	ra,0xffffe
    800064c8:	e92080e7          	jalr	-366(ra) # 80004356 <iput>
  end_op();
    800064cc:	ffffe097          	auipc	ra,0xffffe
    800064d0:	714080e7          	jalr	1812(ra) # 80004be0 <end_op>
  p->cwd = ip;
    800064d4:	14993823          	sd	s1,336(s2)
  return 0;
    800064d8:	4501                	li	a0,0
    800064da:	64aa                	ld	s1,136(sp)
}
    800064dc:	60ea                	ld	ra,152(sp)
    800064de:	644a                	ld	s0,144(sp)
    800064e0:	690a                	ld	s2,128(sp)
    800064e2:	610d                	add	sp,sp,160
    800064e4:	8082                	ret
    800064e6:	64aa                	ld	s1,136(sp)
    end_op();
    800064e8:	ffffe097          	auipc	ra,0xffffe
    800064ec:	6f8080e7          	jalr	1784(ra) # 80004be0 <end_op>
    return -1;
    800064f0:	557d                	li	a0,-1
    800064f2:	b7ed                	j	800064dc <sys_chdir+0x7c>
    iunlockput(ip);
    800064f4:	8526                	mv	a0,s1
    800064f6:	ffffe097          	auipc	ra,0xffffe
    800064fa:	f08080e7          	jalr	-248(ra) # 800043fe <iunlockput>
    end_op();
    800064fe:	ffffe097          	auipc	ra,0xffffe
    80006502:	6e2080e7          	jalr	1762(ra) # 80004be0 <end_op>
    return -1;
    80006506:	557d                	li	a0,-1
    80006508:	64aa                	ld	s1,136(sp)
    8000650a:	bfc9                	j	800064dc <sys_chdir+0x7c>

000000008000650c <sys_exec>:

uint64
sys_exec(void)
{
    8000650c:	7121                	add	sp,sp,-448
    8000650e:	ff06                	sd	ra,440(sp)
    80006510:	fb22                	sd	s0,432(sp)
    80006512:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006514:	e4840593          	add	a1,s0,-440
    80006518:	4505                	li	a0,1
    8000651a:	ffffd097          	auipc	ra,0xffffd
    8000651e:	e96080e7          	jalr	-362(ra) # 800033b0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006522:	08000613          	li	a2,128
    80006526:	f5040593          	add	a1,s0,-176
    8000652a:	4501                	li	a0,0
    8000652c:	ffffd097          	auipc	ra,0xffffd
    80006530:	ea4080e7          	jalr	-348(ra) # 800033d0 <argstr>
    80006534:	87aa                	mv	a5,a0
    return -1;
    80006536:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006538:	0e07c263          	bltz	a5,8000661c <sys_exec+0x110>
    8000653c:	f726                	sd	s1,424(sp)
    8000653e:	f34a                	sd	s2,416(sp)
    80006540:	ef4e                	sd	s3,408(sp)
    80006542:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    80006544:	10000613          	li	a2,256
    80006548:	4581                	li	a1,0
    8000654a:	e5040513          	add	a0,s0,-432
    8000654e:	ffffa097          	auipc	ra,0xffffa
    80006552:	7e6080e7          	jalr	2022(ra) # 80000d34 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006556:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    8000655a:	89a6                	mv	s3,s1
    8000655c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000655e:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006562:	00391513          	sll	a0,s2,0x3
    80006566:	e4040593          	add	a1,s0,-448
    8000656a:	e4843783          	ld	a5,-440(s0)
    8000656e:	953e                	add	a0,a0,a5
    80006570:	ffffd097          	auipc	ra,0xffffd
    80006574:	d82080e7          	jalr	-638(ra) # 800032f2 <fetchaddr>
    80006578:	02054a63          	bltz	a0,800065ac <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    8000657c:	e4043783          	ld	a5,-448(s0)
    80006580:	c7b9                	beqz	a5,800065ce <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006582:	ffffa097          	auipc	ra,0xffffa
    80006586:	5c6080e7          	jalr	1478(ra) # 80000b48 <kalloc>
    8000658a:	85aa                	mv	a1,a0
    8000658c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006590:	cd11                	beqz	a0,800065ac <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006592:	6605                	lui	a2,0x1
    80006594:	e4043503          	ld	a0,-448(s0)
    80006598:	ffffd097          	auipc	ra,0xffffd
    8000659c:	dac080e7          	jalr	-596(ra) # 80003344 <fetchstr>
    800065a0:	00054663          	bltz	a0,800065ac <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    800065a4:	0905                	add	s2,s2,1
    800065a6:	09a1                	add	s3,s3,8
    800065a8:	fb491de3          	bne	s2,s4,80006562 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065ac:	f5040913          	add	s2,s0,-176
    800065b0:	6088                	ld	a0,0(s1)
    800065b2:	c125                	beqz	a0,80006612 <sys_exec+0x106>
    kfree(argv[i]);
    800065b4:	ffffa097          	auipc	ra,0xffffa
    800065b8:	496080e7          	jalr	1174(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065bc:	04a1                	add	s1,s1,8
    800065be:	ff2499e3          	bne	s1,s2,800065b0 <sys_exec+0xa4>
  return -1;
    800065c2:	557d                	li	a0,-1
    800065c4:	74ba                	ld	s1,424(sp)
    800065c6:	791a                	ld	s2,416(sp)
    800065c8:	69fa                	ld	s3,408(sp)
    800065ca:	6a5a                	ld	s4,400(sp)
    800065cc:	a881                	j	8000661c <sys_exec+0x110>
      argv[i] = 0;
    800065ce:	0009079b          	sext.w	a5,s2
    800065d2:	078e                	sll	a5,a5,0x3
    800065d4:	fd078793          	add	a5,a5,-48
    800065d8:	97a2                	add	a5,a5,s0
    800065da:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    800065de:	e5040593          	add	a1,s0,-432
    800065e2:	f5040513          	add	a0,s0,-176
    800065e6:	fffff097          	auipc	ra,0xfffff
    800065ea:	120080e7          	jalr	288(ra) # 80005706 <exec>
    800065ee:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065f0:	f5040993          	add	s3,s0,-176
    800065f4:	6088                	ld	a0,0(s1)
    800065f6:	c901                	beqz	a0,80006606 <sys_exec+0xfa>
    kfree(argv[i]);
    800065f8:	ffffa097          	auipc	ra,0xffffa
    800065fc:	452080e7          	jalr	1106(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006600:	04a1                	add	s1,s1,8
    80006602:	ff3499e3          	bne	s1,s3,800065f4 <sys_exec+0xe8>
  return ret;
    80006606:	854a                	mv	a0,s2
    80006608:	74ba                	ld	s1,424(sp)
    8000660a:	791a                	ld	s2,416(sp)
    8000660c:	69fa                	ld	s3,408(sp)
    8000660e:	6a5a                	ld	s4,400(sp)
    80006610:	a031                	j	8000661c <sys_exec+0x110>
  return -1;
    80006612:	557d                	li	a0,-1
    80006614:	74ba                	ld	s1,424(sp)
    80006616:	791a                	ld	s2,416(sp)
    80006618:	69fa                	ld	s3,408(sp)
    8000661a:	6a5a                	ld	s4,400(sp)
}
    8000661c:	70fa                	ld	ra,440(sp)
    8000661e:	745a                	ld	s0,432(sp)
    80006620:	6139                	add	sp,sp,448
    80006622:	8082                	ret

0000000080006624 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006624:	7139                	add	sp,sp,-64
    80006626:	fc06                	sd	ra,56(sp)
    80006628:	f822                	sd	s0,48(sp)
    8000662a:	f426                	sd	s1,40(sp)
    8000662c:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000662e:	ffffb097          	auipc	ra,0xffffb
    80006632:	55c080e7          	jalr	1372(ra) # 80001b8a <myproc>
    80006636:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006638:	fd840593          	add	a1,s0,-40
    8000663c:	4501                	li	a0,0
    8000663e:	ffffd097          	auipc	ra,0xffffd
    80006642:	d72080e7          	jalr	-654(ra) # 800033b0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006646:	fc840593          	add	a1,s0,-56
    8000664a:	fd040513          	add	a0,s0,-48
    8000664e:	fffff097          	auipc	ra,0xfffff
    80006652:	d50080e7          	jalr	-688(ra) # 8000539e <pipealloc>
    return -1;
    80006656:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006658:	0c054463          	bltz	a0,80006720 <sys_pipe+0xfc>
  fd0 = -1;
    8000665c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006660:	fd043503          	ld	a0,-48(s0)
    80006664:	fffff097          	auipc	ra,0xfffff
    80006668:	4e0080e7          	jalr	1248(ra) # 80005b44 <fdalloc>
    8000666c:	fca42223          	sw	a0,-60(s0)
    80006670:	08054b63          	bltz	a0,80006706 <sys_pipe+0xe2>
    80006674:	fc843503          	ld	a0,-56(s0)
    80006678:	fffff097          	auipc	ra,0xfffff
    8000667c:	4cc080e7          	jalr	1228(ra) # 80005b44 <fdalloc>
    80006680:	fca42023          	sw	a0,-64(s0)
    80006684:	06054863          	bltz	a0,800066f4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006688:	4691                	li	a3,4
    8000668a:	fc440613          	add	a2,s0,-60
    8000668e:	fd843583          	ld	a1,-40(s0)
    80006692:	68a8                	ld	a0,80(s1)
    80006694:	ffffb097          	auipc	ra,0xffffb
    80006698:	04a080e7          	jalr	74(ra) # 800016de <copyout>
    8000669c:	02054063          	bltz	a0,800066bc <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800066a0:	4691                	li	a3,4
    800066a2:	fc040613          	add	a2,s0,-64
    800066a6:	fd843583          	ld	a1,-40(s0)
    800066aa:	0591                	add	a1,a1,4
    800066ac:	68a8                	ld	a0,80(s1)
    800066ae:	ffffb097          	auipc	ra,0xffffb
    800066b2:	030080e7          	jalr	48(ra) # 800016de <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800066b6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066b8:	06055463          	bgez	a0,80006720 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800066bc:	fc442783          	lw	a5,-60(s0)
    800066c0:	07e9                	add	a5,a5,26
    800066c2:	078e                	sll	a5,a5,0x3
    800066c4:	97a6                	add	a5,a5,s1
    800066c6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800066ca:	fc042783          	lw	a5,-64(s0)
    800066ce:	07e9                	add	a5,a5,26
    800066d0:	078e                	sll	a5,a5,0x3
    800066d2:	94be                	add	s1,s1,a5
    800066d4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800066d8:	fd043503          	ld	a0,-48(s0)
    800066dc:	fffff097          	auipc	ra,0xfffff
    800066e0:	954080e7          	jalr	-1708(ra) # 80005030 <fileclose>
    fileclose(wf);
    800066e4:	fc843503          	ld	a0,-56(s0)
    800066e8:	fffff097          	auipc	ra,0xfffff
    800066ec:	948080e7          	jalr	-1720(ra) # 80005030 <fileclose>
    return -1;
    800066f0:	57fd                	li	a5,-1
    800066f2:	a03d                	j	80006720 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800066f4:	fc442783          	lw	a5,-60(s0)
    800066f8:	0007c763          	bltz	a5,80006706 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800066fc:	07e9                	add	a5,a5,26
    800066fe:	078e                	sll	a5,a5,0x3
    80006700:	97a6                	add	a5,a5,s1
    80006702:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006706:	fd043503          	ld	a0,-48(s0)
    8000670a:	fffff097          	auipc	ra,0xfffff
    8000670e:	926080e7          	jalr	-1754(ra) # 80005030 <fileclose>
    fileclose(wf);
    80006712:	fc843503          	ld	a0,-56(s0)
    80006716:	fffff097          	auipc	ra,0xfffff
    8000671a:	91a080e7          	jalr	-1766(ra) # 80005030 <fileclose>
    return -1;
    8000671e:	57fd                	li	a5,-1
}
    80006720:	853e                	mv	a0,a5
    80006722:	70e2                	ld	ra,56(sp)
    80006724:	7442                	ld	s0,48(sp)
    80006726:	74a2                	ld	s1,40(sp)
    80006728:	6121                	add	sp,sp,64
    8000672a:	8082                	ret
    8000672c:	0000                	unimp
	...

0000000080006730 <kernelvec>:
    80006730:	7111                	add	sp,sp,-256
    80006732:	e006                	sd	ra,0(sp)
    80006734:	e40a                	sd	sp,8(sp)
    80006736:	e80e                	sd	gp,16(sp)
    80006738:	ec12                	sd	tp,24(sp)
    8000673a:	f016                	sd	t0,32(sp)
    8000673c:	f41a                	sd	t1,40(sp)
    8000673e:	f81e                	sd	t2,48(sp)
    80006740:	fc22                	sd	s0,56(sp)
    80006742:	e0a6                	sd	s1,64(sp)
    80006744:	e4aa                	sd	a0,72(sp)
    80006746:	e8ae                	sd	a1,80(sp)
    80006748:	ecb2                	sd	a2,88(sp)
    8000674a:	f0b6                	sd	a3,96(sp)
    8000674c:	f4ba                	sd	a4,104(sp)
    8000674e:	f8be                	sd	a5,112(sp)
    80006750:	fcc2                	sd	a6,120(sp)
    80006752:	e146                	sd	a7,128(sp)
    80006754:	e54a                	sd	s2,136(sp)
    80006756:	e94e                	sd	s3,144(sp)
    80006758:	ed52                	sd	s4,152(sp)
    8000675a:	f156                	sd	s5,160(sp)
    8000675c:	f55a                	sd	s6,168(sp)
    8000675e:	f95e                	sd	s7,176(sp)
    80006760:	fd62                	sd	s8,184(sp)
    80006762:	e1e6                	sd	s9,192(sp)
    80006764:	e5ea                	sd	s10,200(sp)
    80006766:	e9ee                	sd	s11,208(sp)
    80006768:	edf2                	sd	t3,216(sp)
    8000676a:	f1f6                	sd	t4,224(sp)
    8000676c:	f5fa                	sd	t5,232(sp)
    8000676e:	f9fe                	sd	t6,240(sp)
    80006770:	9a3fc0ef          	jal	80003112 <kerneltrap>
    80006774:	6082                	ld	ra,0(sp)
    80006776:	6122                	ld	sp,8(sp)
    80006778:	61c2                	ld	gp,16(sp)
    8000677a:	7282                	ld	t0,32(sp)
    8000677c:	7322                	ld	t1,40(sp)
    8000677e:	73c2                	ld	t2,48(sp)
    80006780:	7462                	ld	s0,56(sp)
    80006782:	6486                	ld	s1,64(sp)
    80006784:	6526                	ld	a0,72(sp)
    80006786:	65c6                	ld	a1,80(sp)
    80006788:	6666                	ld	a2,88(sp)
    8000678a:	7686                	ld	a3,96(sp)
    8000678c:	7726                	ld	a4,104(sp)
    8000678e:	77c6                	ld	a5,112(sp)
    80006790:	7866                	ld	a6,120(sp)
    80006792:	688a                	ld	a7,128(sp)
    80006794:	692a                	ld	s2,136(sp)
    80006796:	69ca                	ld	s3,144(sp)
    80006798:	6a6a                	ld	s4,152(sp)
    8000679a:	7a8a                	ld	s5,160(sp)
    8000679c:	7b2a                	ld	s6,168(sp)
    8000679e:	7bca                	ld	s7,176(sp)
    800067a0:	7c6a                	ld	s8,184(sp)
    800067a2:	6c8e                	ld	s9,192(sp)
    800067a4:	6d2e                	ld	s10,200(sp)
    800067a6:	6dce                	ld	s11,208(sp)
    800067a8:	6e6e                	ld	t3,216(sp)
    800067aa:	7e8e                	ld	t4,224(sp)
    800067ac:	7f2e                	ld	t5,232(sp)
    800067ae:	7fce                	ld	t6,240(sp)
    800067b0:	6111                	add	sp,sp,256
    800067b2:	10200073          	sret
    800067b6:	00000013          	nop
    800067ba:	00000013          	nop
    800067be:	0001                	nop

00000000800067c0 <timervec>:
    800067c0:	34051573          	csrrw	a0,mscratch,a0
    800067c4:	e10c                	sd	a1,0(a0)
    800067c6:	e510                	sd	a2,8(a0)
    800067c8:	e914                	sd	a3,16(a0)
    800067ca:	6d0c                	ld	a1,24(a0)
    800067cc:	7110                	ld	a2,32(a0)
    800067ce:	6194                	ld	a3,0(a1)
    800067d0:	96b2                	add	a3,a3,a2
    800067d2:	e194                	sd	a3,0(a1)
    800067d4:	4589                	li	a1,2
    800067d6:	14459073          	csrw	sip,a1
    800067da:	6914                	ld	a3,16(a0)
    800067dc:	6510                	ld	a2,8(a0)
    800067de:	610c                	ld	a1,0(a0)
    800067e0:	34051573          	csrrw	a0,mscratch,a0
    800067e4:	30200073          	mret
	...

00000000800067ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800067ea:	1141                	add	sp,sp,-16
    800067ec:	e422                	sd	s0,8(sp)
    800067ee:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800067f0:	0c0007b7          	lui	a5,0xc000
    800067f4:	4705                	li	a4,1
    800067f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800067f8:	0c0007b7          	lui	a5,0xc000
    800067fc:	c3d8                	sw	a4,4(a5)
}
    800067fe:	6422                	ld	s0,8(sp)
    80006800:	0141                	add	sp,sp,16
    80006802:	8082                	ret

0000000080006804 <plicinithart>:

void
plicinithart(void)
{
    80006804:	1141                	add	sp,sp,-16
    80006806:	e406                	sd	ra,8(sp)
    80006808:	e022                	sd	s0,0(sp)
    8000680a:	0800                	add	s0,sp,16
  int hart = cpuid();
    8000680c:	ffffb097          	auipc	ra,0xffffb
    80006810:	352080e7          	jalr	850(ra) # 80001b5e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006814:	0085171b          	sllw	a4,a0,0x8
    80006818:	0c0027b7          	lui	a5,0xc002
    8000681c:	97ba                	add	a5,a5,a4
    8000681e:	40200713          	li	a4,1026
    80006822:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006826:	00d5151b          	sllw	a0,a0,0xd
    8000682a:	0c2017b7          	lui	a5,0xc201
    8000682e:	97aa                	add	a5,a5,a0
    80006830:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006834:	60a2                	ld	ra,8(sp)
    80006836:	6402                	ld	s0,0(sp)
    80006838:	0141                	add	sp,sp,16
    8000683a:	8082                	ret

000000008000683c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000683c:	1141                	add	sp,sp,-16
    8000683e:	e406                	sd	ra,8(sp)
    80006840:	e022                	sd	s0,0(sp)
    80006842:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006844:	ffffb097          	auipc	ra,0xffffb
    80006848:	31a080e7          	jalr	794(ra) # 80001b5e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    8000684c:	00d5151b          	sllw	a0,a0,0xd
    80006850:	0c2017b7          	lui	a5,0xc201
    80006854:	97aa                	add	a5,a5,a0
  return irq;
}
    80006856:	43c8                	lw	a0,4(a5)
    80006858:	60a2                	ld	ra,8(sp)
    8000685a:	6402                	ld	s0,0(sp)
    8000685c:	0141                	add	sp,sp,16
    8000685e:	8082                	ret

0000000080006860 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006860:	1101                	add	sp,sp,-32
    80006862:	ec06                	sd	ra,24(sp)
    80006864:	e822                	sd	s0,16(sp)
    80006866:	e426                	sd	s1,8(sp)
    80006868:	1000                	add	s0,sp,32
    8000686a:	84aa                	mv	s1,a0
  int hart = cpuid();
    8000686c:	ffffb097          	auipc	ra,0xffffb
    80006870:	2f2080e7          	jalr	754(ra) # 80001b5e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006874:	00d5151b          	sllw	a0,a0,0xd
    80006878:	0c2017b7          	lui	a5,0xc201
    8000687c:	97aa                	add	a5,a5,a0
    8000687e:	c3c4                	sw	s1,4(a5)
}
    80006880:	60e2                	ld	ra,24(sp)
    80006882:	6442                	ld	s0,16(sp)
    80006884:	64a2                	ld	s1,8(sp)
    80006886:	6105                	add	sp,sp,32
    80006888:	8082                	ret

000000008000688a <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    8000688a:	1141                	add	sp,sp,-16
    8000688c:	e406                	sd	ra,8(sp)
    8000688e:	e022                	sd	s0,0(sp)
    80006890:	0800                	add	s0,sp,16
  if(i >= NUM)
    80006892:	479d                	li	a5,7
    80006894:	04a7cc63          	blt	a5,a0,800068ec <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006898:	0001e797          	auipc	a5,0x1e
    8000689c:	ca878793          	add	a5,a5,-856 # 80024540 <disk>
    800068a0:	97aa                	add	a5,a5,a0
    800068a2:	0187c783          	lbu	a5,24(a5)
    800068a6:	ebb9                	bnez	a5,800068fc <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800068a8:	00451693          	sll	a3,a0,0x4
    800068ac:	0001e797          	auipc	a5,0x1e
    800068b0:	c9478793          	add	a5,a5,-876 # 80024540 <disk>
    800068b4:	6398                	ld	a4,0(a5)
    800068b6:	9736                	add	a4,a4,a3
    800068b8:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800068bc:	6398                	ld	a4,0(a5)
    800068be:	9736                	add	a4,a4,a3
    800068c0:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800068c4:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800068c8:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800068cc:	97aa                	add	a5,a5,a0
    800068ce:	4705                	li	a4,1
    800068d0:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800068d4:	0001e517          	auipc	a0,0x1e
    800068d8:	c8450513          	add	a0,a0,-892 # 80024558 <disk+0x18>
    800068dc:	ffffc097          	auipc	ra,0xffffc
    800068e0:	da4080e7          	jalr	-604(ra) # 80002680 <wakeup>
}
    800068e4:	60a2                	ld	ra,8(sp)
    800068e6:	6402                	ld	s0,0(sp)
    800068e8:	0141                	add	sp,sp,16
    800068ea:	8082                	ret
    panic("free_desc 1");
    800068ec:	00003517          	auipc	a0,0x3
    800068f0:	edc50513          	add	a0,a0,-292 # 800097c8 <etext+0x7c8>
    800068f4:	ffffa097          	auipc	ra,0xffffa
    800068f8:	c6c080e7          	jalr	-916(ra) # 80000560 <panic>
    panic("free_desc 2");
    800068fc:	00003517          	auipc	a0,0x3
    80006900:	edc50513          	add	a0,a0,-292 # 800097d8 <etext+0x7d8>
    80006904:	ffffa097          	auipc	ra,0xffffa
    80006908:	c5c080e7          	jalr	-932(ra) # 80000560 <panic>

000000008000690c <virtio_disk_init>:
{
    8000690c:	1101                	add	sp,sp,-32
    8000690e:	ec06                	sd	ra,24(sp)
    80006910:	e822                	sd	s0,16(sp)
    80006912:	e426                	sd	s1,8(sp)
    80006914:	e04a                	sd	s2,0(sp)
    80006916:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006918:	00003597          	auipc	a1,0x3
    8000691c:	ed058593          	add	a1,a1,-304 # 800097e8 <etext+0x7e8>
    80006920:	0001e517          	auipc	a0,0x1e
    80006924:	d4850513          	add	a0,a0,-696 # 80024668 <disk+0x128>
    80006928:	ffffa097          	auipc	ra,0xffffa
    8000692c:	280080e7          	jalr	640(ra) # 80000ba8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006930:	100017b7          	lui	a5,0x10001
    80006934:	4398                	lw	a4,0(a5)
    80006936:	2701                	sext.w	a4,a4
    80006938:	747277b7          	lui	a5,0x74727
    8000693c:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006940:	18f71c63          	bne	a4,a5,80006ad8 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006944:	100017b7          	lui	a5,0x10001
    80006948:	0791                	add	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    8000694a:	439c                	lw	a5,0(a5)
    8000694c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000694e:	4709                	li	a4,2
    80006950:	18e79463          	bne	a5,a4,80006ad8 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006954:	100017b7          	lui	a5,0x10001
    80006958:	07a1                	add	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    8000695a:	439c                	lw	a5,0(a5)
    8000695c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000695e:	16e79d63          	bne	a5,a4,80006ad8 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006962:	100017b7          	lui	a5,0x10001
    80006966:	47d8                	lw	a4,12(a5)
    80006968:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000696a:	554d47b7          	lui	a5,0x554d4
    8000696e:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006972:	16f71363          	bne	a4,a5,80006ad8 <virtio_disk_init+0x1cc>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006976:	100017b7          	lui	a5,0x10001
    8000697a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000697e:	4705                	li	a4,1
    80006980:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006982:	470d                	li	a4,3
    80006984:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006986:	10001737          	lui	a4,0x10001
    8000698a:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000698c:	c7ffe737          	lui	a4,0xc7ffe
    80006990:	75f70713          	add	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd96b7>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006994:	8ef9                	and	a3,a3,a4
    80006996:	10001737          	lui	a4,0x10001
    8000699a:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000699c:	472d                	li	a4,11
    8000699e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069a0:	07078793          	add	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    800069a4:	439c                	lw	a5,0(a5)
    800069a6:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800069aa:	8ba1                	and	a5,a5,8
    800069ac:	12078e63          	beqz	a5,80006ae8 <virtio_disk_init+0x1dc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800069b0:	100017b7          	lui	a5,0x10001
    800069b4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800069b8:	100017b7          	lui	a5,0x10001
    800069bc:	04478793          	add	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    800069c0:	439c                	lw	a5,0(a5)
    800069c2:	2781                	sext.w	a5,a5
    800069c4:	12079a63          	bnez	a5,80006af8 <virtio_disk_init+0x1ec>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800069c8:	100017b7          	lui	a5,0x10001
    800069cc:	03478793          	add	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    800069d0:	439c                	lw	a5,0(a5)
    800069d2:	2781                	sext.w	a5,a5
  if(max == 0)
    800069d4:	12078a63          	beqz	a5,80006b08 <virtio_disk_init+0x1fc>
  if(max < NUM)
    800069d8:	471d                	li	a4,7
    800069da:	12f77f63          	bgeu	a4,a5,80006b18 <virtio_disk_init+0x20c>
  disk.desc = kalloc();
    800069de:	ffffa097          	auipc	ra,0xffffa
    800069e2:	16a080e7          	jalr	362(ra) # 80000b48 <kalloc>
    800069e6:	0001e497          	auipc	s1,0x1e
    800069ea:	b5a48493          	add	s1,s1,-1190 # 80024540 <disk>
    800069ee:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800069f0:	ffffa097          	auipc	ra,0xffffa
    800069f4:	158080e7          	jalr	344(ra) # 80000b48 <kalloc>
    800069f8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800069fa:	ffffa097          	auipc	ra,0xffffa
    800069fe:	14e080e7          	jalr	334(ra) # 80000b48 <kalloc>
    80006a02:	87aa                	mv	a5,a0
    80006a04:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006a06:	6088                	ld	a0,0(s1)
    80006a08:	12050063          	beqz	a0,80006b28 <virtio_disk_init+0x21c>
    80006a0c:	0001e717          	auipc	a4,0x1e
    80006a10:	b3c73703          	ld	a4,-1220(a4) # 80024548 <disk+0x8>
    80006a14:	10070a63          	beqz	a4,80006b28 <virtio_disk_init+0x21c>
    80006a18:	10078863          	beqz	a5,80006b28 <virtio_disk_init+0x21c>
  memset(disk.desc, 0, PGSIZE);
    80006a1c:	6605                	lui	a2,0x1
    80006a1e:	4581                	li	a1,0
    80006a20:	ffffa097          	auipc	ra,0xffffa
    80006a24:	314080e7          	jalr	788(ra) # 80000d34 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006a28:	0001e497          	auipc	s1,0x1e
    80006a2c:	b1848493          	add	s1,s1,-1256 # 80024540 <disk>
    80006a30:	6605                	lui	a2,0x1
    80006a32:	4581                	li	a1,0
    80006a34:	6488                	ld	a0,8(s1)
    80006a36:	ffffa097          	auipc	ra,0xffffa
    80006a3a:	2fe080e7          	jalr	766(ra) # 80000d34 <memset>
  memset(disk.used, 0, PGSIZE);
    80006a3e:	6605                	lui	a2,0x1
    80006a40:	4581                	li	a1,0
    80006a42:	6888                	ld	a0,16(s1)
    80006a44:	ffffa097          	auipc	ra,0xffffa
    80006a48:	2f0080e7          	jalr	752(ra) # 80000d34 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a4c:	100017b7          	lui	a5,0x10001
    80006a50:	4721                	li	a4,8
    80006a52:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006a54:	4098                	lw	a4,0(s1)
    80006a56:	100017b7          	lui	a5,0x10001
    80006a5a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006a5e:	40d8                	lw	a4,4(s1)
    80006a60:	100017b7          	lui	a5,0x10001
    80006a64:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006a68:	649c                	ld	a5,8(s1)
    80006a6a:	0007869b          	sext.w	a3,a5
    80006a6e:	10001737          	lui	a4,0x10001
    80006a72:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006a76:	9781                	sra	a5,a5,0x20
    80006a78:	10001737          	lui	a4,0x10001
    80006a7c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006a80:	689c                	ld	a5,16(s1)
    80006a82:	0007869b          	sext.w	a3,a5
    80006a86:	10001737          	lui	a4,0x10001
    80006a8a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006a8e:	9781                	sra	a5,a5,0x20
    80006a90:	10001737          	lui	a4,0x10001
    80006a94:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006a98:	10001737          	lui	a4,0x10001
    80006a9c:	4785                	li	a5,1
    80006a9e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80006aa0:	00f48c23          	sb	a5,24(s1)
    80006aa4:	00f48ca3          	sb	a5,25(s1)
    80006aa8:	00f48d23          	sb	a5,26(s1)
    80006aac:	00f48da3          	sb	a5,27(s1)
    80006ab0:	00f48e23          	sb	a5,28(s1)
    80006ab4:	00f48ea3          	sb	a5,29(s1)
    80006ab8:	00f48f23          	sb	a5,30(s1)
    80006abc:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006ac0:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ac4:	100017b7          	lui	a5,0x10001
    80006ac8:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    80006acc:	60e2                	ld	ra,24(sp)
    80006ace:	6442                	ld	s0,16(sp)
    80006ad0:	64a2                	ld	s1,8(sp)
    80006ad2:	6902                	ld	s2,0(sp)
    80006ad4:	6105                	add	sp,sp,32
    80006ad6:	8082                	ret
    panic("could not find virtio disk");
    80006ad8:	00003517          	auipc	a0,0x3
    80006adc:	d2050513          	add	a0,a0,-736 # 800097f8 <etext+0x7f8>
    80006ae0:	ffffa097          	auipc	ra,0xffffa
    80006ae4:	a80080e7          	jalr	-1408(ra) # 80000560 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006ae8:	00003517          	auipc	a0,0x3
    80006aec:	d3050513          	add	a0,a0,-720 # 80009818 <etext+0x818>
    80006af0:	ffffa097          	auipc	ra,0xffffa
    80006af4:	a70080e7          	jalr	-1424(ra) # 80000560 <panic>
    panic("virtio disk should not be ready");
    80006af8:	00003517          	auipc	a0,0x3
    80006afc:	d4050513          	add	a0,a0,-704 # 80009838 <etext+0x838>
    80006b00:	ffffa097          	auipc	ra,0xffffa
    80006b04:	a60080e7          	jalr	-1440(ra) # 80000560 <panic>
    panic("virtio disk has no queue 0");
    80006b08:	00003517          	auipc	a0,0x3
    80006b0c:	d5050513          	add	a0,a0,-688 # 80009858 <etext+0x858>
    80006b10:	ffffa097          	auipc	ra,0xffffa
    80006b14:	a50080e7          	jalr	-1456(ra) # 80000560 <panic>
    panic("virtio disk max queue too short");
    80006b18:	00003517          	auipc	a0,0x3
    80006b1c:	d6050513          	add	a0,a0,-672 # 80009878 <etext+0x878>
    80006b20:	ffffa097          	auipc	ra,0xffffa
    80006b24:	a40080e7          	jalr	-1472(ra) # 80000560 <panic>
    panic("virtio disk kalloc");
    80006b28:	00003517          	auipc	a0,0x3
    80006b2c:	d7050513          	add	a0,a0,-656 # 80009898 <etext+0x898>
    80006b30:	ffffa097          	auipc	ra,0xffffa
    80006b34:	a30080e7          	jalr	-1488(ra) # 80000560 <panic>

0000000080006b38 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006b38:	7159                	add	sp,sp,-112
    80006b3a:	f486                	sd	ra,104(sp)
    80006b3c:	f0a2                	sd	s0,96(sp)
    80006b3e:	eca6                	sd	s1,88(sp)
    80006b40:	e8ca                	sd	s2,80(sp)
    80006b42:	e4ce                	sd	s3,72(sp)
    80006b44:	e0d2                	sd	s4,64(sp)
    80006b46:	fc56                	sd	s5,56(sp)
    80006b48:	f85a                	sd	s6,48(sp)
    80006b4a:	f45e                	sd	s7,40(sp)
    80006b4c:	f062                	sd	s8,32(sp)
    80006b4e:	ec66                	sd	s9,24(sp)
    80006b50:	1880                	add	s0,sp,112
    80006b52:	8a2a                	mv	s4,a0
    80006b54:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b56:	00c52c83          	lw	s9,12(a0)
    80006b5a:	001c9c9b          	sllw	s9,s9,0x1
    80006b5e:	1c82                	sll	s9,s9,0x20
    80006b60:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006b64:	0001e517          	auipc	a0,0x1e
    80006b68:	b0450513          	add	a0,a0,-1276 # 80024668 <disk+0x128>
    80006b6c:	ffffa097          	auipc	ra,0xffffa
    80006b70:	0cc080e7          	jalr	204(ra) # 80000c38 <acquire>
  for(int i = 0; i < 3; i++){
    80006b74:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b76:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006b78:	0001eb17          	auipc	s6,0x1e
    80006b7c:	9c8b0b13          	add	s6,s6,-1592 # 80024540 <disk>
  for(int i = 0; i < 3; i++){
    80006b80:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b82:	0001ec17          	auipc	s8,0x1e
    80006b86:	ae6c0c13          	add	s8,s8,-1306 # 80024668 <disk+0x128>
    80006b8a:	a0ad                	j	80006bf4 <virtio_disk_rw+0xbc>
      disk.free[i] = 0;
    80006b8c:	00fb0733          	add	a4,s6,a5
    80006b90:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80006b94:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006b96:	0207c563          	bltz	a5,80006bc0 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006b9a:	2905                	addw	s2,s2,1
    80006b9c:	0611                	add	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80006b9e:	05590f63          	beq	s2,s5,80006bfc <virtio_disk_rw+0xc4>
    idx[i] = alloc_desc();
    80006ba2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006ba4:	0001e717          	auipc	a4,0x1e
    80006ba8:	99c70713          	add	a4,a4,-1636 # 80024540 <disk>
    80006bac:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006bae:	01874683          	lbu	a3,24(a4)
    80006bb2:	fee9                	bnez	a3,80006b8c <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80006bb4:	2785                	addw	a5,a5,1
    80006bb6:	0705                	add	a4,a4,1
    80006bb8:	fe979be3          	bne	a5,s1,80006bae <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006bbc:	57fd                	li	a5,-1
    80006bbe:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006bc0:	03205163          	blez	s2,80006be2 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    80006bc4:	f9042503          	lw	a0,-112(s0)
    80006bc8:	00000097          	auipc	ra,0x0
    80006bcc:	cc2080e7          	jalr	-830(ra) # 8000688a <free_desc>
      for(int j = 0; j < i; j++)
    80006bd0:	4785                	li	a5,1
    80006bd2:	0127d863          	bge	a5,s2,80006be2 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    80006bd6:	f9442503          	lw	a0,-108(s0)
    80006bda:	00000097          	auipc	ra,0x0
    80006bde:	cb0080e7          	jalr	-848(ra) # 8000688a <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006be2:	85e2                	mv	a1,s8
    80006be4:	0001e517          	auipc	a0,0x1e
    80006be8:	97450513          	add	a0,a0,-1676 # 80024558 <disk+0x18>
    80006bec:	ffffc097          	auipc	ra,0xffffc
    80006bf0:	8e4080e7          	jalr	-1820(ra) # 800024d0 <sleep>
  for(int i = 0; i < 3; i++){
    80006bf4:	f9040613          	add	a2,s0,-112
    80006bf8:	894e                	mv	s2,s3
    80006bfa:	b765                	j	80006ba2 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006bfc:	f9042503          	lw	a0,-112(s0)
    80006c00:	00451693          	sll	a3,a0,0x4

  if(write)
    80006c04:	0001e797          	auipc	a5,0x1e
    80006c08:	93c78793          	add	a5,a5,-1732 # 80024540 <disk>
    80006c0c:	00a50713          	add	a4,a0,10
    80006c10:	0712                	sll	a4,a4,0x4
    80006c12:	973e                	add	a4,a4,a5
    80006c14:	01703633          	snez	a2,s7
    80006c18:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006c1a:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006c1e:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c22:	6398                	ld	a4,0(a5)
    80006c24:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c26:	0a868613          	add	a2,a3,168
    80006c2a:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c2c:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c2e:	6390                	ld	a2,0(a5)
    80006c30:	00d605b3          	add	a1,a2,a3
    80006c34:	4741                	li	a4,16
    80006c36:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c38:	4805                	li	a6,1
    80006c3a:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80006c3e:	f9442703          	lw	a4,-108(s0)
    80006c42:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c46:	0712                	sll	a4,a4,0x4
    80006c48:	963a                	add	a2,a2,a4
    80006c4a:	058a0593          	add	a1,s4,88
    80006c4e:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006c50:	0007b883          	ld	a7,0(a5)
    80006c54:	9746                	add	a4,a4,a7
    80006c56:	40000613          	li	a2,1024
    80006c5a:	c710                	sw	a2,8(a4)
  if(write)
    80006c5c:	001bb613          	seqz	a2,s7
    80006c60:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c64:	00166613          	or	a2,a2,1
    80006c68:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006c6c:	f9842583          	lw	a1,-104(s0)
    80006c70:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c74:	00250613          	add	a2,a0,2
    80006c78:	0612                	sll	a2,a2,0x4
    80006c7a:	963e                	add	a2,a2,a5
    80006c7c:	577d                	li	a4,-1
    80006c7e:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c82:	0592                	sll	a1,a1,0x4
    80006c84:	98ae                	add	a7,a7,a1
    80006c86:	03068713          	add	a4,a3,48
    80006c8a:	973e                	add	a4,a4,a5
    80006c8c:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80006c90:	6398                	ld	a4,0(a5)
    80006c92:	972e                	add	a4,a4,a1
    80006c94:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c98:	4689                	li	a3,2
    80006c9a:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80006c9e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006ca2:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80006ca6:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006caa:	6794                	ld	a3,8(a5)
    80006cac:	0026d703          	lhu	a4,2(a3)
    80006cb0:	8b1d                	and	a4,a4,7
    80006cb2:	0706                	sll	a4,a4,0x1
    80006cb4:	96ba                	add	a3,a3,a4
    80006cb6:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006cba:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006cbe:	6798                	ld	a4,8(a5)
    80006cc0:	00275783          	lhu	a5,2(a4)
    80006cc4:	2785                	addw	a5,a5,1
    80006cc6:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006cca:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006cce:	100017b7          	lui	a5,0x10001
    80006cd2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006cd6:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006cda:	0001e917          	auipc	s2,0x1e
    80006cde:	98e90913          	add	s2,s2,-1650 # 80024668 <disk+0x128>
  while(b->disk == 1) {
    80006ce2:	4485                	li	s1,1
    80006ce4:	01079c63          	bne	a5,a6,80006cfc <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006ce8:	85ca                	mv	a1,s2
    80006cea:	8552                	mv	a0,s4
    80006cec:	ffffb097          	auipc	ra,0xffffb
    80006cf0:	7e4080e7          	jalr	2020(ra) # 800024d0 <sleep>
  while(b->disk == 1) {
    80006cf4:	004a2783          	lw	a5,4(s4)
    80006cf8:	fe9788e3          	beq	a5,s1,80006ce8 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006cfc:	f9042903          	lw	s2,-112(s0)
    80006d00:	00290713          	add	a4,s2,2
    80006d04:	0712                	sll	a4,a4,0x4
    80006d06:	0001e797          	auipc	a5,0x1e
    80006d0a:	83a78793          	add	a5,a5,-1990 # 80024540 <disk>
    80006d0e:	97ba                	add	a5,a5,a4
    80006d10:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006d14:	0001e997          	auipc	s3,0x1e
    80006d18:	82c98993          	add	s3,s3,-2004 # 80024540 <disk>
    80006d1c:	00491713          	sll	a4,s2,0x4
    80006d20:	0009b783          	ld	a5,0(s3)
    80006d24:	97ba                	add	a5,a5,a4
    80006d26:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d2a:	854a                	mv	a0,s2
    80006d2c:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d30:	00000097          	auipc	ra,0x0
    80006d34:	b5a080e7          	jalr	-1190(ra) # 8000688a <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d38:	8885                	and	s1,s1,1
    80006d3a:	f0ed                	bnez	s1,80006d1c <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d3c:	0001e517          	auipc	a0,0x1e
    80006d40:	92c50513          	add	a0,a0,-1748 # 80024668 <disk+0x128>
    80006d44:	ffffa097          	auipc	ra,0xffffa
    80006d48:	fa8080e7          	jalr	-88(ra) # 80000cec <release>
}
    80006d4c:	70a6                	ld	ra,104(sp)
    80006d4e:	7406                	ld	s0,96(sp)
    80006d50:	64e6                	ld	s1,88(sp)
    80006d52:	6946                	ld	s2,80(sp)
    80006d54:	69a6                	ld	s3,72(sp)
    80006d56:	6a06                	ld	s4,64(sp)
    80006d58:	7ae2                	ld	s5,56(sp)
    80006d5a:	7b42                	ld	s6,48(sp)
    80006d5c:	7ba2                	ld	s7,40(sp)
    80006d5e:	7c02                	ld	s8,32(sp)
    80006d60:	6ce2                	ld	s9,24(sp)
    80006d62:	6165                	add	sp,sp,112
    80006d64:	8082                	ret

0000000080006d66 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006d66:	1101                	add	sp,sp,-32
    80006d68:	ec06                	sd	ra,24(sp)
    80006d6a:	e822                	sd	s0,16(sp)
    80006d6c:	e426                	sd	s1,8(sp)
    80006d6e:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006d70:	0001d497          	auipc	s1,0x1d
    80006d74:	7d048493          	add	s1,s1,2000 # 80024540 <disk>
    80006d78:	0001e517          	auipc	a0,0x1e
    80006d7c:	8f050513          	add	a0,a0,-1808 # 80024668 <disk+0x128>
    80006d80:	ffffa097          	auipc	ra,0xffffa
    80006d84:	eb8080e7          	jalr	-328(ra) # 80000c38 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006d88:	100017b7          	lui	a5,0x10001
    80006d8c:	53b8                	lw	a4,96(a5)
    80006d8e:	8b0d                	and	a4,a4,3
    80006d90:	100017b7          	lui	a5,0x10001
    80006d94:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80006d96:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006d9a:	689c                	ld	a5,16(s1)
    80006d9c:	0204d703          	lhu	a4,32(s1)
    80006da0:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80006da4:	04f70863          	beq	a4,a5,80006df4 <virtio_disk_intr+0x8e>
    __sync_synchronize();
    80006da8:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006dac:	6898                	ld	a4,16(s1)
    80006dae:	0204d783          	lhu	a5,32(s1)
    80006db2:	8b9d                	and	a5,a5,7
    80006db4:	078e                	sll	a5,a5,0x3
    80006db6:	97ba                	add	a5,a5,a4
    80006db8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006dba:	00278713          	add	a4,a5,2
    80006dbe:	0712                	sll	a4,a4,0x4
    80006dc0:	9726                	add	a4,a4,s1
    80006dc2:	01074703          	lbu	a4,16(a4)
    80006dc6:	e721                	bnez	a4,80006e0e <virtio_disk_intr+0xa8>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006dc8:	0789                	add	a5,a5,2
    80006dca:	0792                	sll	a5,a5,0x4
    80006dcc:	97a6                	add	a5,a5,s1
    80006dce:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006dd0:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006dd4:	ffffc097          	auipc	ra,0xffffc
    80006dd8:	8ac080e7          	jalr	-1876(ra) # 80002680 <wakeup>

    disk.used_idx += 1;
    80006ddc:	0204d783          	lhu	a5,32(s1)
    80006de0:	2785                	addw	a5,a5,1
    80006de2:	17c2                	sll	a5,a5,0x30
    80006de4:	93c1                	srl	a5,a5,0x30
    80006de6:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006dea:	6898                	ld	a4,16(s1)
    80006dec:	00275703          	lhu	a4,2(a4)
    80006df0:	faf71ce3          	bne	a4,a5,80006da8 <virtio_disk_intr+0x42>
  }

  release(&disk.vdisk_lock);
    80006df4:	0001e517          	auipc	a0,0x1e
    80006df8:	87450513          	add	a0,a0,-1932 # 80024668 <disk+0x128>
    80006dfc:	ffffa097          	auipc	ra,0xffffa
    80006e00:	ef0080e7          	jalr	-272(ra) # 80000cec <release>
}
    80006e04:	60e2                	ld	ra,24(sp)
    80006e06:	6442                	ld	s0,16(sp)
    80006e08:	64a2                	ld	s1,8(sp)
    80006e0a:	6105                	add	sp,sp,32
    80006e0c:	8082                	ret
      panic("virtio_disk_intr status");
    80006e0e:	00003517          	auipc	a0,0x3
    80006e12:	aa250513          	add	a0,a0,-1374 # 800098b0 <etext+0x8b0>
    80006e16:	ffff9097          	auipc	ra,0xffff9
    80006e1a:	74a080e7          	jalr	1866(ra) # 80000560 <panic>

0000000080006e1e <init_mlfq>:



struct _queue mlfq_queue;

void init_mlfq(){
    80006e1e:	1141                	add	sp,sp,-16
    80006e20:	e422                	sd	s0,8(sp)
    80006e22:	0800                	add	s0,sp,16
    for (int i = 0; i<5; i++){
    80006e24:	0001e617          	auipc	a2,0x1e
    80006e28:	25c60613          	add	a2,a2,604 # 80025080 <mlfq_queue+0xa00>
    80006e2c:	0001e717          	auipc	a4,0x1e
    80006e30:	a5470713          	add	a4,a4,-1452 # 80024880 <mlfq_queue+0x200>
    80006e34:	4681                	li	a3,0
        mlfq_queue.proc_queue_max_allowable_ticks[i] = 1 << i;
    80006e36:	4505                	li	a0,1
    for (int i = 0; i<5; i++){
    80006e38:	4595                	li	a1,5
        mlfq_queue.proc_queue_max_allowable_ticks[i] = 1 << i;
    80006e3a:	00d517bb          	sllw	a5,a0,a3
    80006e3e:	ca5c                	sw	a5,20(a2)
        mlfq_queue.proc_queue_size[i] = 0;
    80006e40:	00062023          	sw	zero,0(a2)
        
        // initially there are no processes in any queue
        for (int j = 0; j<NPROC; j++){
    80006e44:	e0070793          	add	a5,a4,-512
            mlfq_queue.multilevel_queues[i][j] = 0;
    80006e48:	0007b023          	sd	zero,0(a5)
        for (int j = 0; j<NPROC; j++){
    80006e4c:	07a1                	add	a5,a5,8
    80006e4e:	fee79de3          	bne	a5,a4,80006e48 <init_mlfq+0x2a>
    for (int i = 0; i<5; i++){
    80006e52:	2685                	addw	a3,a3,1
    80006e54:	0611                	add	a2,a2,4
    80006e56:	20070713          	add	a4,a4,512
    80006e5a:	feb690e3          	bne	a3,a1,80006e3a <init_mlfq+0x1c>
        }
    }
}
    80006e5e:	6422                	ld	s0,8(sp)
    80006e60:	0141                	add	sp,sp,16
    80006e62:	8082                	ret

0000000080006e64 <enque>:

void enque(int queue_number, struct proc* p){
    // checking if queue's size if valid
    if (mlfq_queue.proc_queue_size[queue_number] < 0 || mlfq_queue.proc_queue_size[queue_number] >= NPROC - 1){
    80006e64:	28050713          	add	a4,a0,640
    80006e68:	070a                	sll	a4,a4,0x2
    80006e6a:	0001e797          	auipc	a5,0x1e
    80006e6e:	81678793          	add	a5,a5,-2026 # 80024680 <mlfq_queue>
    80006e72:	97ba                	add	a5,a5,a4
    80006e74:	4394                	lw	a3,0(a5)
    80006e76:	0006871b          	sext.w	a4,a3
    80006e7a:	03e00793          	li	a5,62
    80006e7e:	02e7ed63          	bltu	a5,a4,80006eb8 <enque+0x54>
        panic("mlfq enqued");
    }

    // initializations
    mlfq_queue.multilevel_queues[queue_number][mlfq_queue.proc_queue_size[queue_number]++] = p;
    80006e82:	0001d717          	auipc	a4,0x1d
    80006e86:	7fe70713          	add	a4,a4,2046 # 80024680 <mlfq_queue>
    80006e8a:	28050793          	add	a5,a0,640
    80006e8e:	078a                	sll	a5,a5,0x2
    80006e90:	97ba                	add	a5,a5,a4
    80006e92:	0016861b          	addw	a2,a3,1
    80006e96:	c390                	sw	a2,0(a5)
    80006e98:	00651793          	sll	a5,a0,0x6
    80006e9c:	97b6                	add	a5,a5,a3
    80006e9e:	078e                	sll	a5,a5,0x3
    80006ea0:	973e                	add	a4,a4,a5
    80006ea2:	e30c                	sd	a1,0(a4)
    
    #ifdef MLFQTEST
    printf("((pid:%d ticks:%d queuenum:%d))\n", p->pid, ticks, p->queue_num);
    #endif

    p->wait_time = 0;
    80006ea4:	1a05a623          	sw	zero,428(a1)
    p->queue_num = queue_number;
    80006ea8:	1aa5aa23          	sw	a0,436(a1)
    p->is_in_queue = 1;
    80006eac:	4785                	li	a5,1
    80006eae:	1af5a823          	sw	a5,432(a1)
    p->curr_run_time = 0;
    80006eb2:	1a05ac23          	sw	zero,440(a1)
    80006eb6:	8082                	ret
void enque(int queue_number, struct proc* p){
    80006eb8:	1141                	add	sp,sp,-16
    80006eba:	e406                	sd	ra,8(sp)
    80006ebc:	e022                	sd	s0,0(sp)
    80006ebe:	0800                	add	s0,sp,16
        panic("mlfq enqued");
    80006ec0:	00003517          	auipc	a0,0x3
    80006ec4:	a0850513          	add	a0,a0,-1528 # 800098c8 <etext+0x8c8>
    80006ec8:	ffff9097          	auipc	ra,0xffff9
    80006ecc:	698080e7          	jalr	1688(ra) # 80000560 <panic>

0000000080006ed0 <remove_process>:

// returns the process itself if found in queue
// returns 0 otherwise
struct proc* remove_process(int queue_number, struct proc* p){
    // checking if queue's size if valid
    if (mlfq_queue.proc_queue_size[queue_number] <= 0 || mlfq_queue.proc_queue_size[queue_number] >= NPROC){
    80006ed0:	28050713          	add	a4,a0,640
    80006ed4:	070a                	sll	a4,a4,0x2
    80006ed6:	0001d797          	auipc	a5,0x1d
    80006eda:	7aa78793          	add	a5,a5,1962 # 80024680 <mlfq_queue>
    80006ede:	97ba                	add	a5,a5,a4
    80006ee0:	0007a803          	lw	a6,0(a5)
    80006ee4:	fff8071b          	addw	a4,a6,-1
    80006ee8:	03e00793          	li	a5,62
    80006eec:	02e7e563          	bltu	a5,a4,80006f16 <remove_process+0x46>
    80006ef0:	00951793          	sll	a5,a0,0x9
    80006ef4:	0001d717          	auipc	a4,0x1d
    80006ef8:	78c70713          	add	a4,a4,1932 # 80024680 <mlfq_queue>
    80006efc:	97ba                	add	a5,a5,a4
        panic("mlfq remove from between");
    }

    for (int proc_ind = 0; proc_ind < NPROC ; proc_ind++){
    80006efe:	4701                	li	a4,0
    80006f00:	04000613          	li	a2,64
        if (mlfq_queue.multilevel_queues[queue_number][proc_ind] == p){
    80006f04:	6394                	ld	a3,0(a5)
    80006f06:	02b68463          	beq	a3,a1,80006f2e <remove_process+0x5e>
    for (int proc_ind = 0; proc_ind < NPROC ; proc_ind++){
    80006f0a:	2705                	addw	a4,a4,1
    80006f0c:	07a1                	add	a5,a5,8
    80006f0e:	fec71be3          	bne	a4,a2,80006f04 <remove_process+0x34>

            return p;
        }
    }

    return 0;
    80006f12:	4501                	li	a0,0
}
    80006f14:	8082                	ret
struct proc* remove_process(int queue_number, struct proc* p){
    80006f16:	1141                	add	sp,sp,-16
    80006f18:	e406                	sd	ra,8(sp)
    80006f1a:	e022                	sd	s0,0(sp)
    80006f1c:	0800                	add	s0,sp,16
        panic("mlfq remove from between");
    80006f1e:	00003517          	auipc	a0,0x3
    80006f22:	9ba50513          	add	a0,a0,-1606 # 800098d8 <etext+0x8d8>
    80006f26:	ffff9097          	auipc	ra,0xffff9
    80006f2a:	63a080e7          	jalr	1594(ra) # 80000560 <panic>
            for (int next_ind =  proc_ind; next_ind < NPROC - 1; next_ind++){
    80006f2e:	03e00793          	li	a5,62
    80006f32:	02e7ce63          	blt	a5,a4,80006f6e <remove_process+0x9e>
    80006f36:	00651613          	sll	a2,a0,0x6
    80006f3a:	963a                	add	a2,a2,a4
    80006f3c:	00361793          	sll	a5,a2,0x3
    80006f40:	0001d697          	auipc	a3,0x1d
    80006f44:	74068693          	add	a3,a3,1856 # 80024680 <mlfq_queue>
    80006f48:	97b6                	add	a5,a5,a3
    80006f4a:	03e00693          	li	a3,62
    80006f4e:	40e6873b          	subw	a4,a3,a4
    80006f52:	1702                	sll	a4,a4,0x20
    80006f54:	9301                	srl	a4,a4,0x20
    80006f56:	9732                	add	a4,a4,a2
    80006f58:	070e                	sll	a4,a4,0x3
    80006f5a:	0001d697          	auipc	a3,0x1d
    80006f5e:	72e68693          	add	a3,a3,1838 # 80024688 <mlfq_queue+0x8>
    80006f62:	9736                	add	a4,a4,a3
                mlfq_queue.multilevel_queues[queue_number][next_ind] = mlfq_queue.multilevel_queues[queue_number][next_ind+1]; 
    80006f64:	6794                	ld	a3,8(a5)
    80006f66:	e394                	sd	a3,0(a5)
            for (int next_ind =  proc_ind; next_ind < NPROC - 1; next_ind++){
    80006f68:	07a1                	add	a5,a5,8
    80006f6a:	fee79de3          	bne	a5,a4,80006f64 <remove_process+0x94>
            mlfq_queue.multilevel_queues[queue_number][NPROC - 1] = 0;
    80006f6e:	0001d797          	auipc	a5,0x1d
    80006f72:	71278793          	add	a5,a5,1810 # 80024680 <mlfq_queue>
    80006f76:	00951713          	sll	a4,a0,0x9
    80006f7a:	973e                	add	a4,a4,a5
    80006f7c:	1e073c23          	sd	zero,504(a4)
            mlfq_queue.proc_queue_size[queue_number]--;
    80006f80:	28050513          	add	a0,a0,640
    80006f84:	050a                	sll	a0,a0,0x2
    80006f86:	97aa                	add	a5,a5,a0
    80006f88:	387d                	addw	a6,a6,-1
    80006f8a:	0107a023          	sw	a6,0(a5)
            p->is_in_queue = 0;
    80006f8e:	1a05a823          	sw	zero,432(a1)
            return p;
    80006f92:	852e                	mv	a0,a1
    80006f94:	8082                	ret

0000000080006f96 <remove_first>:

// returns the front of the queue, if the queue is not empty
// panics otherwise and returns 0
struct proc* remove_first(int queue_number){
    // checking if queue's size if valid
    if (mlfq_queue.proc_queue_size[queue_number] <= 0 || mlfq_queue.proc_queue_size[queue_number] >= NPROC){
    80006f96:	28050693          	add	a3,a0,640
    80006f9a:	068a                	sll	a3,a3,0x2
    80006f9c:	0001d717          	auipc	a4,0x1d
    80006fa0:	6e470713          	add	a4,a4,1764 # 80024680 <mlfq_queue>
    80006fa4:	9736                	add	a4,a4,a3
    80006fa6:	4318                	lw	a4,0(a4)
    80006fa8:	377d                	addw	a4,a4,-1
    80006faa:	03e00693          	li	a3,62
    80006fae:	02e6e163          	bltu	a3,a4,80006fd0 <remove_first+0x3a>
    80006fb2:	87aa                	mv	a5,a0
        panic("mlfq deque");
        return 0;
    }

    // accessing front of queue
    struct proc* p = mlfq_queue.multilevel_queues[queue_number][0];
    80006fb4:	00951693          	sll	a3,a0,0x9
    80006fb8:	0001d717          	auipc	a4,0x1d
    80006fbc:	6c870713          	add	a4,a4,1736 # 80024680 <mlfq_queue>
    80006fc0:	9736                	add	a4,a4,a3
    80006fc2:	6308                	ld	a0,0(a4)

    // process is no longer in queue
    p->is_in_queue = 0;
    80006fc4:	1a052823          	sw	zero,432(a0)

    for (int proc_ind = 0; proc_ind < 1 ; proc_ind++){
        if (mlfq_queue.multilevel_queues[queue_number][proc_ind] == p){
    80006fc8:	6318                	ld	a4,0(a4)
    80006fca:	00a70f63          	beq	a4,a0,80006fe8 <remove_first+0x52>
            return p;
        }
    }    

    return p;   
    80006fce:	8082                	ret
struct proc* remove_first(int queue_number){
    80006fd0:	1141                	add	sp,sp,-16
    80006fd2:	e406                	sd	ra,8(sp)
    80006fd4:	e022                	sd	s0,0(sp)
    80006fd6:	0800                	add	s0,sp,16
        panic("mlfq deque");
    80006fd8:	00003517          	auipc	a0,0x3
    80006fdc:	92050513          	add	a0,a0,-1760 # 800098f8 <etext+0x8f8>
    80006fe0:	ffff9097          	auipc	ra,0xffff9
    80006fe4:	580080e7          	jalr	1408(ra) # 80000560 <panic>
    80006fe8:	0001d717          	auipc	a4,0x1d
    80006fec:	69870713          	add	a4,a4,1688 # 80024680 <mlfq_queue>
    80006ff0:	9736                	add	a4,a4,a3
    80006ff2:	0001e617          	auipc	a2,0x1e
    80006ff6:	88660613          	add	a2,a2,-1914 # 80024878 <mlfq_queue+0x1f8>
    80006ffa:	9636                	add	a2,a2,a3
                mlfq_queue.multilevel_queues[queue_number][next_ind] = mlfq_queue.multilevel_queues[queue_number][next_ind+1]; 
    80006ffc:	6714                	ld	a3,8(a4)
    80006ffe:	e314                	sd	a3,0(a4)
            for (int next_ind =  proc_ind; next_ind < NPROC - 1; next_ind++){
    80007000:	0721                	add	a4,a4,8
    80007002:	fec71de3          	bne	a4,a2,80006ffc <remove_first+0x66>
            mlfq_queue.multilevel_queues[queue_number][NPROC - 1] = 0;
    80007006:	0001d717          	auipc	a4,0x1d
    8000700a:	67a70713          	add	a4,a4,1658 # 80024680 <mlfq_queue>
    8000700e:	00979693          	sll	a3,a5,0x9
    80007012:	96ba                	add	a3,a3,a4
    80007014:	1e06bc23          	sd	zero,504(a3)
            mlfq_queue.proc_queue_size[queue_number]--;
    80007018:	28078793          	add	a5,a5,640
    8000701c:	078a                	sll	a5,a5,0x2
    8000701e:	97ba                	add	a5,a5,a4
    80007020:	4398                	lw	a4,0(a5)
    80007022:	377d                	addw	a4,a4,-1
    80007024:	c398                	sw	a4,0(a5)
            p->is_in_queue = 0;
    80007026:	1a052823          	sw	zero,432(a0)
            p->curr_run_time = 0;
    8000702a:	1a052c23          	sw	zero,440(a0)
            return p;
    8000702e:	8082                	ret
	...

0000000080008000 <_trampoline>:
    80008000:	14051073          	csrw	sscratch,a0
    80008004:	02000537          	lui	a0,0x2000
    80008008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000800a:	0536                	sll	a0,a0,0xd
    8000800c:	02153423          	sd	ra,40(a0)
    80008010:	02253823          	sd	sp,48(a0)
    80008014:	02353c23          	sd	gp,56(a0)
    80008018:	04453023          	sd	tp,64(a0)
    8000801c:	04553423          	sd	t0,72(a0)
    80008020:	04653823          	sd	t1,80(a0)
    80008024:	04753c23          	sd	t2,88(a0)
    80008028:	f120                	sd	s0,96(a0)
    8000802a:	f524                	sd	s1,104(a0)
    8000802c:	fd2c                	sd	a1,120(a0)
    8000802e:	e150                	sd	a2,128(a0)
    80008030:	e554                	sd	a3,136(a0)
    80008032:	e958                	sd	a4,144(a0)
    80008034:	ed5c                	sd	a5,152(a0)
    80008036:	0b053023          	sd	a6,160(a0)
    8000803a:	0b153423          	sd	a7,168(a0)
    8000803e:	0b253823          	sd	s2,176(a0)
    80008042:	0b353c23          	sd	s3,184(a0)
    80008046:	0d453023          	sd	s4,192(a0)
    8000804a:	0d553423          	sd	s5,200(a0)
    8000804e:	0d653823          	sd	s6,208(a0)
    80008052:	0d753c23          	sd	s7,216(a0)
    80008056:	0f853023          	sd	s8,224(a0)
    8000805a:	0f953423          	sd	s9,232(a0)
    8000805e:	0fa53823          	sd	s10,240(a0)
    80008062:	0fb53c23          	sd	s11,248(a0)
    80008066:	11c53023          	sd	t3,256(a0)
    8000806a:	11d53423          	sd	t4,264(a0)
    8000806e:	11e53823          	sd	t5,272(a0)
    80008072:	11f53c23          	sd	t6,280(a0)
    80008076:	140022f3          	csrr	t0,sscratch
    8000807a:	06553823          	sd	t0,112(a0)
    8000807e:	00853103          	ld	sp,8(a0)
    80008082:	02053203          	ld	tp,32(a0)
    80008086:	01053283          	ld	t0,16(a0)
    8000808a:	00053303          	ld	t1,0(a0)
    8000808e:	12000073          	sfence.vma
    80008092:	18031073          	csrw	satp,t1
    80008096:	12000073          	sfence.vma
    8000809a:	8282                	jr	t0

000000008000809c <userret>:
    8000809c:	12000073          	sfence.vma
    800080a0:	18051073          	csrw	satp,a0
    800080a4:	12000073          	sfence.vma
    800080a8:	02000537          	lui	a0,0x2000
    800080ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800080ae:	0536                	sll	a0,a0,0xd
    800080b0:	02853083          	ld	ra,40(a0)
    800080b4:	03053103          	ld	sp,48(a0)
    800080b8:	03853183          	ld	gp,56(a0)
    800080bc:	04053203          	ld	tp,64(a0)
    800080c0:	04853283          	ld	t0,72(a0)
    800080c4:	05053303          	ld	t1,80(a0)
    800080c8:	05853383          	ld	t2,88(a0)
    800080cc:	7120                	ld	s0,96(a0)
    800080ce:	7524                	ld	s1,104(a0)
    800080d0:	7d2c                	ld	a1,120(a0)
    800080d2:	6150                	ld	a2,128(a0)
    800080d4:	6554                	ld	a3,136(a0)
    800080d6:	6958                	ld	a4,144(a0)
    800080d8:	6d5c                	ld	a5,152(a0)
    800080da:	0a053803          	ld	a6,160(a0)
    800080de:	0a853883          	ld	a7,168(a0)
    800080e2:	0b053903          	ld	s2,176(a0)
    800080e6:	0b853983          	ld	s3,184(a0)
    800080ea:	0c053a03          	ld	s4,192(a0)
    800080ee:	0c853a83          	ld	s5,200(a0)
    800080f2:	0d053b03          	ld	s6,208(a0)
    800080f6:	0d853b83          	ld	s7,216(a0)
    800080fa:	0e053c03          	ld	s8,224(a0)
    800080fe:	0e853c83          	ld	s9,232(a0)
    80008102:	0f053d03          	ld	s10,240(a0)
    80008106:	0f853d83          	ld	s11,248(a0)
    8000810a:	10053e03          	ld	t3,256(a0)
    8000810e:	10853e83          	ld	t4,264(a0)
    80008112:	11053f03          	ld	t5,272(a0)
    80008116:	11853f83          	ld	t6,280(a0)
    8000811a:	7928                	ld	a0,112(a0)
    8000811c:	10200073          	sret
	...
