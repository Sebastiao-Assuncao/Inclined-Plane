# Sin list
import math
senos = []
for i in range(91):  # Returns a list wiht sin (ang) * 9.8, for 0 <= ang <=90
    ang = math.radians(i)
    seno_inicial = (math.sin(ang))
    seno_g = seno_inicial * 9.8
    senos.append(seno_g)


cont = 1
time = 8  # Real Time/8 sec
t = 1/8  # Time interval
vel = 0  # Initial velocity, updated throughout the cycle
pos = 0  # Initial position, updated throughout the cycle
ang = 30  # Inclined plane angle


def acl_x(ang):
    """Returns the value of sin(ang) * 9.8"""

    return senos[ang]


def velocity(vel, acl):
    """Returns the current velocity using V = Vo + acl*t, Vo = velocity in the beggining of the time interval"""

    return vel + acl*t


def position(pos, vel):
    """Returns the current positin using P = Po + Vt, V = current velocity; Po = Position in the beggining of the time interval"""

    return pos + vel*t


# Computed the acceleration. Doesn't change throughout the all execution
acl = acl_x(ang)
print("Acceleration =", acl, "m/s^2")


for _ in range(time):
    vel = velocity(vel, acl)  # Updates current velocity
    print("Current velocity:", vel, "m/s")
    pos = position(pos, vel)  # Updates current position
    print("Current position:", pos, "m")
    print("\n")
