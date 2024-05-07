
user/_setpriority:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "../kernel/types.h"
#include "../kernel/syscall.h"
#include "user.h"

int main(int argc, char **argv)
{
   0:	1101                	add	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	1000                	add	s0,sp,32
    // 3 arguments needed : setpriority, priority and pid
    if (argc != 3)
   8:	478d                	li	a5,3
   a:	02f50163          	beq	a0,a5,2c <main+0x2c>
   e:	e426                	sd	s1,8(sp)
  10:	e04a                	sd	s2,0(sp)
    {
        printf("Usage : setpriority priority pid\n");
  12:	00001517          	auipc	a0,0x1
  16:	81e50513          	add	a0,a0,-2018 # 830 <malloc+0x104>
  1a:	00000097          	auipc	ra,0x0
  1e:	65a080e7          	jalr	1626(ra) # 674 <printf>
        exit(1);
  22:	4505                	li	a0,1
  24:	00000097          	auipc	ra,0x0
  28:	2c0080e7          	jalr	704(ra) # 2e4 <exit>
  2c:	e426                	sd	s1,8(sp)
  2e:	e04a                	sd	s2,0(sp)
  30:	84ae                	mv	s1,a1
    }

    int new_priority = atoi(argv[1]);
  32:	6588                	ld	a0,8(a1)
  34:	00000097          	auipc	ra,0x0
  38:	1b6080e7          	jalr	438(ra) # 1ea <atoi>
  3c:	892a                	mv	s2,a0
    int pid = atoi(argv[2]);
  3e:	6888                	ld	a0,16(s1)
  40:	00000097          	auipc	ra,0x0
  44:	1aa080e7          	jalr	426(ra) # 1ea <atoi>
  48:	85aa                	mv	a1,a0
    
    set_priority(new_priority, pid);
  4a:	854a                	mv	a0,s2
  4c:	00000097          	auipc	ra,0x0
  50:	358080e7          	jalr	856(ra) # 3a4 <set_priority>
    
    exit(0);
  54:	4501                	li	a0,0
  56:	00000097          	auipc	ra,0x0
  5a:	28e080e7          	jalr	654(ra) # 2e4 <exit>

000000000000005e <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  5e:	1141                	add	sp,sp,-16
  60:	e406                	sd	ra,8(sp)
  62:	e022                	sd	s0,0(sp)
  64:	0800                	add	s0,sp,16
  extern int main();
  main();
  66:	00000097          	auipc	ra,0x0
  6a:	f9a080e7          	jalr	-102(ra) # 0 <main>
  exit(0);
  6e:	4501                	li	a0,0
  70:	00000097          	auipc	ra,0x0
  74:	274080e7          	jalr	628(ra) # 2e4 <exit>

0000000000000078 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  78:	1141                	add	sp,sp,-16
  7a:	e422                	sd	s0,8(sp)
  7c:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  7e:	87aa                	mv	a5,a0
  80:	0585                	add	a1,a1,1
  82:	0785                	add	a5,a5,1
  84:	fff5c703          	lbu	a4,-1(a1)
  88:	fee78fa3          	sb	a4,-1(a5)
  8c:	fb75                	bnez	a4,80 <strcpy+0x8>
    ;
  return os;
}
  8e:	6422                	ld	s0,8(sp)
  90:	0141                	add	sp,sp,16
  92:	8082                	ret

0000000000000094 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  94:	1141                	add	sp,sp,-16
  96:	e422                	sd	s0,8(sp)
  98:	0800                	add	s0,sp,16
  while(*p && *p == *q)
  9a:	00054783          	lbu	a5,0(a0)
  9e:	cb91                	beqz	a5,b2 <strcmp+0x1e>
  a0:	0005c703          	lbu	a4,0(a1)
  a4:	00f71763          	bne	a4,a5,b2 <strcmp+0x1e>
    p++, q++;
  a8:	0505                	add	a0,a0,1
  aa:	0585                	add	a1,a1,1
  while(*p && *p == *q)
  ac:	00054783          	lbu	a5,0(a0)
  b0:	fbe5                	bnez	a5,a0 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  b2:	0005c503          	lbu	a0,0(a1)
}
  b6:	40a7853b          	subw	a0,a5,a0
  ba:	6422                	ld	s0,8(sp)
  bc:	0141                	add	sp,sp,16
  be:	8082                	ret

00000000000000c0 <strlen>:

uint
strlen(const char *s)
{
  c0:	1141                	add	sp,sp,-16
  c2:	e422                	sd	s0,8(sp)
  c4:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  c6:	00054783          	lbu	a5,0(a0)
  ca:	cf91                	beqz	a5,e6 <strlen+0x26>
  cc:	0505                	add	a0,a0,1
  ce:	87aa                	mv	a5,a0
  d0:	86be                	mv	a3,a5
  d2:	0785                	add	a5,a5,1
  d4:	fff7c703          	lbu	a4,-1(a5)
  d8:	ff65                	bnez	a4,d0 <strlen+0x10>
  da:	40a6853b          	subw	a0,a3,a0
  de:	2505                	addw	a0,a0,1
    ;
  return n;
}
  e0:	6422                	ld	s0,8(sp)
  e2:	0141                	add	sp,sp,16
  e4:	8082                	ret
  for(n = 0; s[n]; n++)
  e6:	4501                	li	a0,0
  e8:	bfe5                	j	e0 <strlen+0x20>

00000000000000ea <memset>:

void*
memset(void *dst, int c, uint n)
{
  ea:	1141                	add	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  f0:	ca19                	beqz	a2,106 <memset+0x1c>
  f2:	87aa                	mv	a5,a0
  f4:	1602                	sll	a2,a2,0x20
  f6:	9201                	srl	a2,a2,0x20
  f8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  fc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 100:	0785                	add	a5,a5,1
 102:	fee79de3          	bne	a5,a4,fc <memset+0x12>
  }
  return dst;
}
 106:	6422                	ld	s0,8(sp)
 108:	0141                	add	sp,sp,16
 10a:	8082                	ret

000000000000010c <strchr>:

char*
strchr(const char *s, char c)
{
 10c:	1141                	add	sp,sp,-16
 10e:	e422                	sd	s0,8(sp)
 110:	0800                	add	s0,sp,16
  for(; *s; s++)
 112:	00054783          	lbu	a5,0(a0)
 116:	cb99                	beqz	a5,12c <strchr+0x20>
    if(*s == c)
 118:	00f58763          	beq	a1,a5,126 <strchr+0x1a>
  for(; *s; s++)
 11c:	0505                	add	a0,a0,1
 11e:	00054783          	lbu	a5,0(a0)
 122:	fbfd                	bnez	a5,118 <strchr+0xc>
      return (char*)s;
  return 0;
 124:	4501                	li	a0,0
}
 126:	6422                	ld	s0,8(sp)
 128:	0141                	add	sp,sp,16
 12a:	8082                	ret
  return 0;
 12c:	4501                	li	a0,0
 12e:	bfe5                	j	126 <strchr+0x1a>

0000000000000130 <gets>:

char*
gets(char *buf, int max)
{
 130:	711d                	add	sp,sp,-96
 132:	ec86                	sd	ra,88(sp)
 134:	e8a2                	sd	s0,80(sp)
 136:	e4a6                	sd	s1,72(sp)
 138:	e0ca                	sd	s2,64(sp)
 13a:	fc4e                	sd	s3,56(sp)
 13c:	f852                	sd	s4,48(sp)
 13e:	f456                	sd	s5,40(sp)
 140:	f05a                	sd	s6,32(sp)
 142:	ec5e                	sd	s7,24(sp)
 144:	1080                	add	s0,sp,96
 146:	8baa                	mv	s7,a0
 148:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 14a:	892a                	mv	s2,a0
 14c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 14e:	4aa9                	li	s5,10
 150:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 152:	89a6                	mv	s3,s1
 154:	2485                	addw	s1,s1,1
 156:	0344d863          	bge	s1,s4,186 <gets+0x56>
    cc = read(0, &c, 1);
 15a:	4605                	li	a2,1
 15c:	faf40593          	add	a1,s0,-81
 160:	4501                	li	a0,0
 162:	00000097          	auipc	ra,0x0
 166:	19a080e7          	jalr	410(ra) # 2fc <read>
    if(cc < 1)
 16a:	00a05e63          	blez	a0,186 <gets+0x56>
    buf[i++] = c;
 16e:	faf44783          	lbu	a5,-81(s0)
 172:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 176:	01578763          	beq	a5,s5,184 <gets+0x54>
 17a:	0905                	add	s2,s2,1
 17c:	fd679be3          	bne	a5,s6,152 <gets+0x22>
    buf[i++] = c;
 180:	89a6                	mv	s3,s1
 182:	a011                	j	186 <gets+0x56>
 184:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 186:	99de                	add	s3,s3,s7
 188:	00098023          	sb	zero,0(s3)
  return buf;
}
 18c:	855e                	mv	a0,s7
 18e:	60e6                	ld	ra,88(sp)
 190:	6446                	ld	s0,80(sp)
 192:	64a6                	ld	s1,72(sp)
 194:	6906                	ld	s2,64(sp)
 196:	79e2                	ld	s3,56(sp)
 198:	7a42                	ld	s4,48(sp)
 19a:	7aa2                	ld	s5,40(sp)
 19c:	7b02                	ld	s6,32(sp)
 19e:	6be2                	ld	s7,24(sp)
 1a0:	6125                	add	sp,sp,96
 1a2:	8082                	ret

00000000000001a4 <stat>:

int
stat(const char *n, struct stat *st)
{
 1a4:	1101                	add	sp,sp,-32
 1a6:	ec06                	sd	ra,24(sp)
 1a8:	e822                	sd	s0,16(sp)
 1aa:	e04a                	sd	s2,0(sp)
 1ac:	1000                	add	s0,sp,32
 1ae:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1b0:	4581                	li	a1,0
 1b2:	00000097          	auipc	ra,0x0
 1b6:	172080e7          	jalr	370(ra) # 324 <open>
  if(fd < 0)
 1ba:	02054663          	bltz	a0,1e6 <stat+0x42>
 1be:	e426                	sd	s1,8(sp)
 1c0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1c2:	85ca                	mv	a1,s2
 1c4:	00000097          	auipc	ra,0x0
 1c8:	178080e7          	jalr	376(ra) # 33c <fstat>
 1cc:	892a                	mv	s2,a0
  close(fd);
 1ce:	8526                	mv	a0,s1
 1d0:	00000097          	auipc	ra,0x0
 1d4:	13c080e7          	jalr	316(ra) # 30c <close>
  return r;
 1d8:	64a2                	ld	s1,8(sp)
}
 1da:	854a                	mv	a0,s2
 1dc:	60e2                	ld	ra,24(sp)
 1de:	6442                	ld	s0,16(sp)
 1e0:	6902                	ld	s2,0(sp)
 1e2:	6105                	add	sp,sp,32
 1e4:	8082                	ret
    return -1;
 1e6:	597d                	li	s2,-1
 1e8:	bfcd                	j	1da <stat+0x36>

00000000000001ea <atoi>:

int
atoi(const char *s)
{
 1ea:	1141                	add	sp,sp,-16
 1ec:	e422                	sd	s0,8(sp)
 1ee:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1f0:	00054683          	lbu	a3,0(a0)
 1f4:	fd06879b          	addw	a5,a3,-48
 1f8:	0ff7f793          	zext.b	a5,a5
 1fc:	4625                	li	a2,9
 1fe:	02f66863          	bltu	a2,a5,22e <atoi+0x44>
 202:	872a                	mv	a4,a0
  n = 0;
 204:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 206:	0705                	add	a4,a4,1
 208:	0025179b          	sllw	a5,a0,0x2
 20c:	9fa9                	addw	a5,a5,a0
 20e:	0017979b          	sllw	a5,a5,0x1
 212:	9fb5                	addw	a5,a5,a3
 214:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 218:	00074683          	lbu	a3,0(a4)
 21c:	fd06879b          	addw	a5,a3,-48
 220:	0ff7f793          	zext.b	a5,a5
 224:	fef671e3          	bgeu	a2,a5,206 <atoi+0x1c>
  return n;
}
 228:	6422                	ld	s0,8(sp)
 22a:	0141                	add	sp,sp,16
 22c:	8082                	ret
  n = 0;
 22e:	4501                	li	a0,0
 230:	bfe5                	j	228 <atoi+0x3e>

0000000000000232 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 232:	1141                	add	sp,sp,-16
 234:	e422                	sd	s0,8(sp)
 236:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 238:	02b57463          	bgeu	a0,a1,260 <memmove+0x2e>
    while(n-- > 0)
 23c:	00c05f63          	blez	a2,25a <memmove+0x28>
 240:	1602                	sll	a2,a2,0x20
 242:	9201                	srl	a2,a2,0x20
 244:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 248:	872a                	mv	a4,a0
      *dst++ = *src++;
 24a:	0585                	add	a1,a1,1
 24c:	0705                	add	a4,a4,1
 24e:	fff5c683          	lbu	a3,-1(a1)
 252:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 256:	fef71ae3          	bne	a4,a5,24a <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 25a:	6422                	ld	s0,8(sp)
 25c:	0141                	add	sp,sp,16
 25e:	8082                	ret
    dst += n;
 260:	00c50733          	add	a4,a0,a2
    src += n;
 264:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 266:	fec05ae3          	blez	a2,25a <memmove+0x28>
 26a:	fff6079b          	addw	a5,a2,-1
 26e:	1782                	sll	a5,a5,0x20
 270:	9381                	srl	a5,a5,0x20
 272:	fff7c793          	not	a5,a5
 276:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 278:	15fd                	add	a1,a1,-1
 27a:	177d                	add	a4,a4,-1
 27c:	0005c683          	lbu	a3,0(a1)
 280:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 284:	fee79ae3          	bne	a5,a4,278 <memmove+0x46>
 288:	bfc9                	j	25a <memmove+0x28>

000000000000028a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 28a:	1141                	add	sp,sp,-16
 28c:	e422                	sd	s0,8(sp)
 28e:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 290:	ca05                	beqz	a2,2c0 <memcmp+0x36>
 292:	fff6069b          	addw	a3,a2,-1
 296:	1682                	sll	a3,a3,0x20
 298:	9281                	srl	a3,a3,0x20
 29a:	0685                	add	a3,a3,1
 29c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 29e:	00054783          	lbu	a5,0(a0)
 2a2:	0005c703          	lbu	a4,0(a1)
 2a6:	00e79863          	bne	a5,a4,2b6 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2aa:	0505                	add	a0,a0,1
    p2++;
 2ac:	0585                	add	a1,a1,1
  while (n-- > 0) {
 2ae:	fed518e3          	bne	a0,a3,29e <memcmp+0x14>
  }
  return 0;
 2b2:	4501                	li	a0,0
 2b4:	a019                	j	2ba <memcmp+0x30>
      return *p1 - *p2;
 2b6:	40e7853b          	subw	a0,a5,a4
}
 2ba:	6422                	ld	s0,8(sp)
 2bc:	0141                	add	sp,sp,16
 2be:	8082                	ret
  return 0;
 2c0:	4501                	li	a0,0
 2c2:	bfe5                	j	2ba <memcmp+0x30>

00000000000002c4 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2c4:	1141                	add	sp,sp,-16
 2c6:	e406                	sd	ra,8(sp)
 2c8:	e022                	sd	s0,0(sp)
 2ca:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 2cc:	00000097          	auipc	ra,0x0
 2d0:	f66080e7          	jalr	-154(ra) # 232 <memmove>
}
 2d4:	60a2                	ld	ra,8(sp)
 2d6:	6402                	ld	s0,0(sp)
 2d8:	0141                	add	sp,sp,16
 2da:	8082                	ret

00000000000002dc <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2dc:	4885                	li	a7,1
 ecall
 2de:	00000073          	ecall
 ret
 2e2:	8082                	ret

00000000000002e4 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2e4:	4889                	li	a7,2
 ecall
 2e6:	00000073          	ecall
 ret
 2ea:	8082                	ret

00000000000002ec <wait>:
.global wait
wait:
 li a7, SYS_wait
 2ec:	488d                	li	a7,3
 ecall
 2ee:	00000073          	ecall
 ret
 2f2:	8082                	ret

00000000000002f4 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2f4:	4891                	li	a7,4
 ecall
 2f6:	00000073          	ecall
 ret
 2fa:	8082                	ret

00000000000002fc <read>:
.global read
read:
 li a7, SYS_read
 2fc:	4895                	li	a7,5
 ecall
 2fe:	00000073          	ecall
 ret
 302:	8082                	ret

0000000000000304 <write>:
.global write
write:
 li a7, SYS_write
 304:	48c1                	li	a7,16
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <close>:
.global close
close:
 li a7, SYS_close
 30c:	48d5                	li	a7,21
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <kill>:
.global kill
kill:
 li a7, SYS_kill
 314:	4899                	li	a7,6
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <exec>:
.global exec
exec:
 li a7, SYS_exec
 31c:	489d                	li	a7,7
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <open>:
.global open
open:
 li a7, SYS_open
 324:	48bd                	li	a7,15
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 32c:	48c5                	li	a7,17
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 334:	48c9                	li	a7,18
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 33c:	48a1                	li	a7,8
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <link>:
.global link
link:
 li a7, SYS_link
 344:	48cd                	li	a7,19
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 34c:	48d1                	li	a7,20
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 354:	48a5                	li	a7,9
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <dup>:
.global dup
dup:
 li a7, SYS_dup
 35c:	48a9                	li	a7,10
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 364:	48ad                	li	a7,11
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 36c:	48b1                	li	a7,12
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 374:	48b5                	li	a7,13
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 37c:	48b9                	li	a7,14
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <trace>:
.global trace
trace:
 li a7, SYS_trace
 384:	48d9                	li	a7,22
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 38c:	48dd                	li	a7,23
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 394:	48e1                	li	a7,24
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 39c:	48e5                	li	a7,25
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 3a4:	48e9                	li	a7,26
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3ac:	1101                	add	sp,sp,-32
 3ae:	ec06                	sd	ra,24(sp)
 3b0:	e822                	sd	s0,16(sp)
 3b2:	1000                	add	s0,sp,32
 3b4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3b8:	4605                	li	a2,1
 3ba:	fef40593          	add	a1,s0,-17
 3be:	00000097          	auipc	ra,0x0
 3c2:	f46080e7          	jalr	-186(ra) # 304 <write>
}
 3c6:	60e2                	ld	ra,24(sp)
 3c8:	6442                	ld	s0,16(sp)
 3ca:	6105                	add	sp,sp,32
 3cc:	8082                	ret

00000000000003ce <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3ce:	7139                	add	sp,sp,-64
 3d0:	fc06                	sd	ra,56(sp)
 3d2:	f822                	sd	s0,48(sp)
 3d4:	f426                	sd	s1,40(sp)
 3d6:	0080                	add	s0,sp,64
 3d8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3da:	c299                	beqz	a3,3e0 <printint+0x12>
 3dc:	0805cb63          	bltz	a1,472 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3e0:	2581                	sext.w	a1,a1
  neg = 0;
 3e2:	4881                	li	a7,0
 3e4:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 3e8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3ea:	2601                	sext.w	a2,a2
 3ec:	00000517          	auipc	a0,0x0
 3f0:	4cc50513          	add	a0,a0,1228 # 8b8 <digits>
 3f4:	883a                	mv	a6,a4
 3f6:	2705                	addw	a4,a4,1
 3f8:	02c5f7bb          	remuw	a5,a1,a2
 3fc:	1782                	sll	a5,a5,0x20
 3fe:	9381                	srl	a5,a5,0x20
 400:	97aa                	add	a5,a5,a0
 402:	0007c783          	lbu	a5,0(a5)
 406:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 40a:	0005879b          	sext.w	a5,a1
 40e:	02c5d5bb          	divuw	a1,a1,a2
 412:	0685                	add	a3,a3,1
 414:	fec7f0e3          	bgeu	a5,a2,3f4 <printint+0x26>
  if(neg)
 418:	00088c63          	beqz	a7,430 <printint+0x62>
    buf[i++] = '-';
 41c:	fd070793          	add	a5,a4,-48
 420:	00878733          	add	a4,a5,s0
 424:	02d00793          	li	a5,45
 428:	fef70823          	sb	a5,-16(a4)
 42c:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 430:	02e05c63          	blez	a4,468 <printint+0x9a>
 434:	f04a                	sd	s2,32(sp)
 436:	ec4e                	sd	s3,24(sp)
 438:	fc040793          	add	a5,s0,-64
 43c:	00e78933          	add	s2,a5,a4
 440:	fff78993          	add	s3,a5,-1
 444:	99ba                	add	s3,s3,a4
 446:	377d                	addw	a4,a4,-1
 448:	1702                	sll	a4,a4,0x20
 44a:	9301                	srl	a4,a4,0x20
 44c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 450:	fff94583          	lbu	a1,-1(s2)
 454:	8526                	mv	a0,s1
 456:	00000097          	auipc	ra,0x0
 45a:	f56080e7          	jalr	-170(ra) # 3ac <putc>
  while(--i >= 0)
 45e:	197d                	add	s2,s2,-1
 460:	ff3918e3          	bne	s2,s3,450 <printint+0x82>
 464:	7902                	ld	s2,32(sp)
 466:	69e2                	ld	s3,24(sp)
}
 468:	70e2                	ld	ra,56(sp)
 46a:	7442                	ld	s0,48(sp)
 46c:	74a2                	ld	s1,40(sp)
 46e:	6121                	add	sp,sp,64
 470:	8082                	ret
    x = -xx;
 472:	40b005bb          	negw	a1,a1
    neg = 1;
 476:	4885                	li	a7,1
    x = -xx;
 478:	b7b5                	j	3e4 <printint+0x16>

000000000000047a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 47a:	715d                	add	sp,sp,-80
 47c:	e486                	sd	ra,72(sp)
 47e:	e0a2                	sd	s0,64(sp)
 480:	f84a                	sd	s2,48(sp)
 482:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 484:	0005c903          	lbu	s2,0(a1)
 488:	1a090a63          	beqz	s2,63c <vprintf+0x1c2>
 48c:	fc26                	sd	s1,56(sp)
 48e:	f44e                	sd	s3,40(sp)
 490:	f052                	sd	s4,32(sp)
 492:	ec56                	sd	s5,24(sp)
 494:	e85a                	sd	s6,16(sp)
 496:	e45e                	sd	s7,8(sp)
 498:	8aaa                	mv	s5,a0
 49a:	8bb2                	mv	s7,a2
 49c:	00158493          	add	s1,a1,1
  state = 0;
 4a0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4a2:	02500a13          	li	s4,37
 4a6:	4b55                	li	s6,21
 4a8:	a839                	j	4c6 <vprintf+0x4c>
        putc(fd, c);
 4aa:	85ca                	mv	a1,s2
 4ac:	8556                	mv	a0,s5
 4ae:	00000097          	auipc	ra,0x0
 4b2:	efe080e7          	jalr	-258(ra) # 3ac <putc>
 4b6:	a019                	j	4bc <vprintf+0x42>
    } else if(state == '%'){
 4b8:	01498d63          	beq	s3,s4,4d2 <vprintf+0x58>
  for(i = 0; fmt[i]; i++){
 4bc:	0485                	add	s1,s1,1
 4be:	fff4c903          	lbu	s2,-1(s1)
 4c2:	16090763          	beqz	s2,630 <vprintf+0x1b6>
    if(state == 0){
 4c6:	fe0999e3          	bnez	s3,4b8 <vprintf+0x3e>
      if(c == '%'){
 4ca:	ff4910e3          	bne	s2,s4,4aa <vprintf+0x30>
        state = '%';
 4ce:	89d2                	mv	s3,s4
 4d0:	b7f5                	j	4bc <vprintf+0x42>
      if(c == 'd'){
 4d2:	13490463          	beq	s2,s4,5fa <vprintf+0x180>
 4d6:	f9d9079b          	addw	a5,s2,-99
 4da:	0ff7f793          	zext.b	a5,a5
 4de:	12fb6763          	bltu	s6,a5,60c <vprintf+0x192>
 4e2:	f9d9079b          	addw	a5,s2,-99
 4e6:	0ff7f713          	zext.b	a4,a5
 4ea:	12eb6163          	bltu	s6,a4,60c <vprintf+0x192>
 4ee:	00271793          	sll	a5,a4,0x2
 4f2:	00000717          	auipc	a4,0x0
 4f6:	36e70713          	add	a4,a4,878 # 860 <malloc+0x134>
 4fa:	97ba                	add	a5,a5,a4
 4fc:	439c                	lw	a5,0(a5)
 4fe:	97ba                	add	a5,a5,a4
 500:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 502:	008b8913          	add	s2,s7,8
 506:	4685                	li	a3,1
 508:	4629                	li	a2,10
 50a:	000ba583          	lw	a1,0(s7)
 50e:	8556                	mv	a0,s5
 510:	00000097          	auipc	ra,0x0
 514:	ebe080e7          	jalr	-322(ra) # 3ce <printint>
 518:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 51a:	4981                	li	s3,0
 51c:	b745                	j	4bc <vprintf+0x42>
        printint(fd, va_arg(ap, uint64), 10, 0);
 51e:	008b8913          	add	s2,s7,8
 522:	4681                	li	a3,0
 524:	4629                	li	a2,10
 526:	000ba583          	lw	a1,0(s7)
 52a:	8556                	mv	a0,s5
 52c:	00000097          	auipc	ra,0x0
 530:	ea2080e7          	jalr	-350(ra) # 3ce <printint>
 534:	8bca                	mv	s7,s2
      state = 0;
 536:	4981                	li	s3,0
 538:	b751                	j	4bc <vprintf+0x42>
        printint(fd, va_arg(ap, int), 16, 0);
 53a:	008b8913          	add	s2,s7,8
 53e:	4681                	li	a3,0
 540:	4641                	li	a2,16
 542:	000ba583          	lw	a1,0(s7)
 546:	8556                	mv	a0,s5
 548:	00000097          	auipc	ra,0x0
 54c:	e86080e7          	jalr	-378(ra) # 3ce <printint>
 550:	8bca                	mv	s7,s2
      state = 0;
 552:	4981                	li	s3,0
 554:	b7a5                	j	4bc <vprintf+0x42>
 556:	e062                	sd	s8,0(sp)
        printptr(fd, va_arg(ap, uint64));
 558:	008b8c13          	add	s8,s7,8
 55c:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 560:	03000593          	li	a1,48
 564:	8556                	mv	a0,s5
 566:	00000097          	auipc	ra,0x0
 56a:	e46080e7          	jalr	-442(ra) # 3ac <putc>
  putc(fd, 'x');
 56e:	07800593          	li	a1,120
 572:	8556                	mv	a0,s5
 574:	00000097          	auipc	ra,0x0
 578:	e38080e7          	jalr	-456(ra) # 3ac <putc>
 57c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 57e:	00000b97          	auipc	s7,0x0
 582:	33ab8b93          	add	s7,s7,826 # 8b8 <digits>
 586:	03c9d793          	srl	a5,s3,0x3c
 58a:	97de                	add	a5,a5,s7
 58c:	0007c583          	lbu	a1,0(a5)
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	e1a080e7          	jalr	-486(ra) # 3ac <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 59a:	0992                	sll	s3,s3,0x4
 59c:	397d                	addw	s2,s2,-1
 59e:	fe0914e3          	bnez	s2,586 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 5a2:	8be2                	mv	s7,s8
      state = 0;
 5a4:	4981                	li	s3,0
 5a6:	6c02                	ld	s8,0(sp)
 5a8:	bf11                	j	4bc <vprintf+0x42>
        s = va_arg(ap, char*);
 5aa:	008b8993          	add	s3,s7,8
 5ae:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 5b2:	02090163          	beqz	s2,5d4 <vprintf+0x15a>
        while(*s != 0){
 5b6:	00094583          	lbu	a1,0(s2)
 5ba:	c9a5                	beqz	a1,62a <vprintf+0x1b0>
          putc(fd, *s);
 5bc:	8556                	mv	a0,s5
 5be:	00000097          	auipc	ra,0x0
 5c2:	dee080e7          	jalr	-530(ra) # 3ac <putc>
          s++;
 5c6:	0905                	add	s2,s2,1
        while(*s != 0){
 5c8:	00094583          	lbu	a1,0(s2)
 5cc:	f9e5                	bnez	a1,5bc <vprintf+0x142>
        s = va_arg(ap, char*);
 5ce:	8bce                	mv	s7,s3
      state = 0;
 5d0:	4981                	li	s3,0
 5d2:	b5ed                	j	4bc <vprintf+0x42>
          s = "(null)";
 5d4:	00000917          	auipc	s2,0x0
 5d8:	28490913          	add	s2,s2,644 # 858 <malloc+0x12c>
        while(*s != 0){
 5dc:	02800593          	li	a1,40
 5e0:	bff1                	j	5bc <vprintf+0x142>
        putc(fd, va_arg(ap, uint));
 5e2:	008b8913          	add	s2,s7,8
 5e6:	000bc583          	lbu	a1,0(s7)
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	dc0080e7          	jalr	-576(ra) # 3ac <putc>
 5f4:	8bca                	mv	s7,s2
      state = 0;
 5f6:	4981                	li	s3,0
 5f8:	b5d1                	j	4bc <vprintf+0x42>
        putc(fd, c);
 5fa:	02500593          	li	a1,37
 5fe:	8556                	mv	a0,s5
 600:	00000097          	auipc	ra,0x0
 604:	dac080e7          	jalr	-596(ra) # 3ac <putc>
      state = 0;
 608:	4981                	li	s3,0
 60a:	bd4d                	j	4bc <vprintf+0x42>
        putc(fd, '%');
 60c:	02500593          	li	a1,37
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	d9a080e7          	jalr	-614(ra) # 3ac <putc>
        putc(fd, c);
 61a:	85ca                	mv	a1,s2
 61c:	8556                	mv	a0,s5
 61e:	00000097          	auipc	ra,0x0
 622:	d8e080e7          	jalr	-626(ra) # 3ac <putc>
      state = 0;
 626:	4981                	li	s3,0
 628:	bd51                	j	4bc <vprintf+0x42>
        s = va_arg(ap, char*);
 62a:	8bce                	mv	s7,s3
      state = 0;
 62c:	4981                	li	s3,0
 62e:	b579                	j	4bc <vprintf+0x42>
 630:	74e2                	ld	s1,56(sp)
 632:	79a2                	ld	s3,40(sp)
 634:	7a02                	ld	s4,32(sp)
 636:	6ae2                	ld	s5,24(sp)
 638:	6b42                	ld	s6,16(sp)
 63a:	6ba2                	ld	s7,8(sp)
    }
  }
}
 63c:	60a6                	ld	ra,72(sp)
 63e:	6406                	ld	s0,64(sp)
 640:	7942                	ld	s2,48(sp)
 642:	6161                	add	sp,sp,80
 644:	8082                	ret

0000000000000646 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 646:	715d                	add	sp,sp,-80
 648:	ec06                	sd	ra,24(sp)
 64a:	e822                	sd	s0,16(sp)
 64c:	1000                	add	s0,sp,32
 64e:	e010                	sd	a2,0(s0)
 650:	e414                	sd	a3,8(s0)
 652:	e818                	sd	a4,16(s0)
 654:	ec1c                	sd	a5,24(s0)
 656:	03043023          	sd	a6,32(s0)
 65a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 65e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 662:	8622                	mv	a2,s0
 664:	00000097          	auipc	ra,0x0
 668:	e16080e7          	jalr	-490(ra) # 47a <vprintf>
}
 66c:	60e2                	ld	ra,24(sp)
 66e:	6442                	ld	s0,16(sp)
 670:	6161                	add	sp,sp,80
 672:	8082                	ret

0000000000000674 <printf>:

void
printf(const char *fmt, ...)
{
 674:	711d                	add	sp,sp,-96
 676:	ec06                	sd	ra,24(sp)
 678:	e822                	sd	s0,16(sp)
 67a:	1000                	add	s0,sp,32
 67c:	e40c                	sd	a1,8(s0)
 67e:	e810                	sd	a2,16(s0)
 680:	ec14                	sd	a3,24(s0)
 682:	f018                	sd	a4,32(s0)
 684:	f41c                	sd	a5,40(s0)
 686:	03043823          	sd	a6,48(s0)
 68a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 68e:	00840613          	add	a2,s0,8
 692:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 696:	85aa                	mv	a1,a0
 698:	4505                	li	a0,1
 69a:	00000097          	auipc	ra,0x0
 69e:	de0080e7          	jalr	-544(ra) # 47a <vprintf>
}
 6a2:	60e2                	ld	ra,24(sp)
 6a4:	6442                	ld	s0,16(sp)
 6a6:	6125                	add	sp,sp,96
 6a8:	8082                	ret

00000000000006aa <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6aa:	1141                	add	sp,sp,-16
 6ac:	e422                	sd	s0,8(sp)
 6ae:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6b0:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6b4:	00001797          	auipc	a5,0x1
 6b8:	94c7b783          	ld	a5,-1716(a5) # 1000 <freep>
 6bc:	a02d                	j	6e6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6be:	4618                	lw	a4,8(a2)
 6c0:	9f2d                	addw	a4,a4,a1
 6c2:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6c6:	6398                	ld	a4,0(a5)
 6c8:	6310                	ld	a2,0(a4)
 6ca:	a83d                	j	708 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6cc:	ff852703          	lw	a4,-8(a0)
 6d0:	9f31                	addw	a4,a4,a2
 6d2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6d4:	ff053683          	ld	a3,-16(a0)
 6d8:	a091                	j	71c <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6da:	6398                	ld	a4,0(a5)
 6dc:	00e7e463          	bltu	a5,a4,6e4 <free+0x3a>
 6e0:	00e6ea63          	bltu	a3,a4,6f4 <free+0x4a>
{
 6e4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6e6:	fed7fae3          	bgeu	a5,a3,6da <free+0x30>
 6ea:	6398                	ld	a4,0(a5)
 6ec:	00e6e463          	bltu	a3,a4,6f4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6f0:	fee7eae3          	bltu	a5,a4,6e4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6f4:	ff852583          	lw	a1,-8(a0)
 6f8:	6390                	ld	a2,0(a5)
 6fa:	02059813          	sll	a6,a1,0x20
 6fe:	01c85713          	srl	a4,a6,0x1c
 702:	9736                	add	a4,a4,a3
 704:	fae60de3          	beq	a2,a4,6be <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 708:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 70c:	4790                	lw	a2,8(a5)
 70e:	02061593          	sll	a1,a2,0x20
 712:	01c5d713          	srl	a4,a1,0x1c
 716:	973e                	add	a4,a4,a5
 718:	fae68ae3          	beq	a3,a4,6cc <free+0x22>
    p->s.ptr = bp->s.ptr;
 71c:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 71e:	00001717          	auipc	a4,0x1
 722:	8ef73123          	sd	a5,-1822(a4) # 1000 <freep>
}
 726:	6422                	ld	s0,8(sp)
 728:	0141                	add	sp,sp,16
 72a:	8082                	ret

000000000000072c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 72c:	7139                	add	sp,sp,-64
 72e:	fc06                	sd	ra,56(sp)
 730:	f822                	sd	s0,48(sp)
 732:	f426                	sd	s1,40(sp)
 734:	ec4e                	sd	s3,24(sp)
 736:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 738:	02051493          	sll	s1,a0,0x20
 73c:	9081                	srl	s1,s1,0x20
 73e:	04bd                	add	s1,s1,15
 740:	8091                	srl	s1,s1,0x4
 742:	0014899b          	addw	s3,s1,1
 746:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 748:	00001517          	auipc	a0,0x1
 74c:	8b853503          	ld	a0,-1864(a0) # 1000 <freep>
 750:	c915                	beqz	a0,784 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 752:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 754:	4798                	lw	a4,8(a5)
 756:	08977e63          	bgeu	a4,s1,7f2 <malloc+0xc6>
 75a:	f04a                	sd	s2,32(sp)
 75c:	e852                	sd	s4,16(sp)
 75e:	e456                	sd	s5,8(sp)
 760:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
 762:	8a4e                	mv	s4,s3
 764:	0009871b          	sext.w	a4,s3
 768:	6685                	lui	a3,0x1
 76a:	00d77363          	bgeu	a4,a3,770 <malloc+0x44>
 76e:	6a05                	lui	s4,0x1
 770:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 774:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 778:	00001917          	auipc	s2,0x1
 77c:	88890913          	add	s2,s2,-1912 # 1000 <freep>
  if(p == (char*)-1)
 780:	5afd                	li	s5,-1
 782:	a091                	j	7c6 <malloc+0x9a>
 784:	f04a                	sd	s2,32(sp)
 786:	e852                	sd	s4,16(sp)
 788:	e456                	sd	s5,8(sp)
 78a:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
 78c:	00001797          	auipc	a5,0x1
 790:	88478793          	add	a5,a5,-1916 # 1010 <base>
 794:	00001717          	auipc	a4,0x1
 798:	86f73623          	sd	a5,-1940(a4) # 1000 <freep>
 79c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 79e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7a2:	b7c1                	j	762 <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
 7a4:	6398                	ld	a4,0(a5)
 7a6:	e118                	sd	a4,0(a0)
 7a8:	a08d                	j	80a <malloc+0xde>
  hp->s.size = nu;
 7aa:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ae:	0541                	add	a0,a0,16
 7b0:	00000097          	auipc	ra,0x0
 7b4:	efa080e7          	jalr	-262(ra) # 6aa <free>
  return freep;
 7b8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7bc:	c13d                	beqz	a0,822 <malloc+0xf6>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7be:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7c0:	4798                	lw	a4,8(a5)
 7c2:	02977463          	bgeu	a4,s1,7ea <malloc+0xbe>
    if(p == freep)
 7c6:	00093703          	ld	a4,0(s2)
 7ca:	853e                	mv	a0,a5
 7cc:	fef719e3          	bne	a4,a5,7be <malloc+0x92>
  p = sbrk(nu * sizeof(Header));
 7d0:	8552                	mv	a0,s4
 7d2:	00000097          	auipc	ra,0x0
 7d6:	b9a080e7          	jalr	-1126(ra) # 36c <sbrk>
  if(p == (char*)-1)
 7da:	fd5518e3          	bne	a0,s5,7aa <malloc+0x7e>
        return 0;
 7de:	4501                	li	a0,0
 7e0:	7902                	ld	s2,32(sp)
 7e2:	6a42                	ld	s4,16(sp)
 7e4:	6aa2                	ld	s5,8(sp)
 7e6:	6b02                	ld	s6,0(sp)
 7e8:	a03d                	j	816 <malloc+0xea>
 7ea:	7902                	ld	s2,32(sp)
 7ec:	6a42                	ld	s4,16(sp)
 7ee:	6aa2                	ld	s5,8(sp)
 7f0:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
 7f2:	fae489e3          	beq	s1,a4,7a4 <malloc+0x78>
        p->s.size -= nunits;
 7f6:	4137073b          	subw	a4,a4,s3
 7fa:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7fc:	02071693          	sll	a3,a4,0x20
 800:	01c6d713          	srl	a4,a3,0x1c
 804:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 806:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 80a:	00000717          	auipc	a4,0x0
 80e:	7ea73b23          	sd	a0,2038(a4) # 1000 <freep>
      return (void*)(p + 1);
 812:	01078513          	add	a0,a5,16
  }
}
 816:	70e2                	ld	ra,56(sp)
 818:	7442                	ld	s0,48(sp)
 81a:	74a2                	ld	s1,40(sp)
 81c:	69e2                	ld	s3,24(sp)
 81e:	6121                	add	sp,sp,64
 820:	8082                	ret
 822:	7902                	ld	s2,32(sp)
 824:	6a42                	ld	s4,16(sp)
 826:	6aa2                	ld	s5,8(sp)
 828:	6b02                	ld	s6,0(sp)
 82a:	b7f5                	j	816 <malloc+0xea>
