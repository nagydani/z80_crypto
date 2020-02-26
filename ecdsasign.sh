#! /bin/bash

PRIV_K="1111111111111111111111111111111111111111111111111111111111111111"

PUBLIC="19e7e376e7c213b7e7e7e46cc70a5dd086daff2a"

# Message signing
MSG="Test message"
LEN=`wc -c <<< "$MSG"`
LEN=`expr $LEN - 1`
HASH=`echo -en "\031Ethereum Signed Message:\0012$LEN$MSG" | sha3sum 256 -k - | awk '{print toupper($1)}'`

PRIV_KR=`echo $PRIV_K | awk '{for(i=length()-1;i>0;i-=2){printf toupper(substr($0,i,2))}}'`

K_PARAM=`echo $HASH$PRIV_KR |xxd -p -r | sha3sum 256 -k - |cut -d' ' -f1 | awk '{for(i=length()-1;i>0;i-=2){printf toupper(substr($0,i,2))}}'`

BC_LINE_LENGTH=0 bc -q << END > /tmp/ecdsasig.txt
ibase=16
obase=10

# Zp modulus
p = 0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F

# Generator order
q = 0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

# Generator
gx = 79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
gy = 483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8

# Private key
d = 0$PRIV_K

# Random parameter
k = 0$K_PARAM

# Message hash
m = 0$HASH

define modinv (x,r) {
	auto a,d,u,v
	if(x%2) u=x else u=x+r
	v=r
	a=0
	d=r-1
	i = 0
	while(v!=1){
		while(v<u){
			u=u-v
			d=(d+a)%r
			while(0==u%2){
				if(d%2) d=d+r
				u=u/2
				d=d/2
			}
		}
		v=v-u
		a=(d+a)%r
		while(0==v%2){
			if(a%2) a=a+r
			v=v/2
			a=a/2
		}
	}
	return (a)
}

define intersect(l,v,ax,ay,bx) {
	x = (l * l)%p
	x = (x - bx + p)%p
	x = (x - ax + p)%p
	v = (ax - x + p)%p
	y = (l * v)%p
	y = (y - ay + p)%p
	return (0)
}

define ecdoub(ax, ay) {
	auto v
	x = (ax * ax) % p
	v = (x + x) % p
	x = (x + v) % p
	y = (ay + ay) % p
	v = modinv(y,p)
	return (intersect((x * v)%p,v,ax,ay,ax))
}

define ecadd(ax,ay,bx,by) {
	auto v
	x = (bx - ax + p)%p
	y = (by - ay + p)%p
	v = modinv(x,p)
	return (intersect((y * v)%p,v,ax,ay,bx))
}

define ecmul(m,ax,ay) {
	auto bx,by,n,v
	n=1
	while(m >= n) {
		n += n
	}
	n /= 2
	bx = ax
	by = ay
	m -= n
	n /= 2
	while(n >= 1) {
		v = ecdoub(bx, by)
		bx = x
		by = y
		if(m >= n) {
			v = ecadd(ax,ay,bx,by)
			bx = x
			by = y
			m -= n
		}
		n /= 2
	}
	x = bx
	y = by
	return (0)
}

# Public key
vv=ecmul(d,gx,gy)
ox = x
oy = y

ki = modinv(k,q)

vv=ecmul(k,gx,gy)
kx=x
ky=y

s = (x * d)%q

z = (m + s)%q

s = (ki * z)%q

r = x

# Message signature
v = 1B + (y%2)

# EIP-155 Tx signature
#v = 25 + (y%2)

# EIP-2
if(s + s > q) {
	v = v + 1 - 2*(y%2)
	s = q - s
}

r
s
v
END

# Signed message formatting

SIG=`head -n3 /tmp/ecdsasig.txt | tr -d '\n'`
cat << END
{
  "address": "0x$PUBLIC",
  "msg": "$MSG",
  "sig": "0x$SIG",
  "version": "2"
}
END
