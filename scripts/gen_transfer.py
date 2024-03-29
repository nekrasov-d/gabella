#!/bin/python3
# Copyright (C) 2021 Dmitriy Nekrasov
#
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
# for more details.
#
# XXX: translate comments
#

import matplotlib.pyplot as plt
import math as m
import argparse

###############################################################################
# Parameters

N = 2**14-1 # Dynamic range
nf = 20     # noise floor
il = 10000  # input limiter

# Параметры, не участвующие в расчёте, нужны для подкрашивания зон на графике
ss = 5000   # soft strum
hs = 8000   # hard strum
pk = 10000  # peak

###############################################################################
# MIF header / annotation

MIF_HEADER = \
"-- This file is automatically generated by gen_transfer.py program\
\n-- Can be used as an overdrive/compressor transfer function wet = f(dry)\
\n-- performed by ROM. To see what it actually does run it with -s argument\
\n-- and same prameters (shows plot of dry and wet transfer functions)\
\n-- Parameters:\
\n-- Dynamic range : 0:%d\
\n-- Noise floor: %d\
\n-- Soft strum: %d (informative)\
\n-- Hard strum: %d (informative)\
\n-- Peak: %d (informative)\
\n-- Input limiter: %d\
\n-- (informative parameters doesn't affect calculation)\
\n\
\nWIDTH=15;\
\nDEPTH=%d;\
\nADDRESS_RADIX=HEX;\
\nDATA_RADIX=HEX;\
\n\n" % ( N, nf, ss, hs, pk, il, N+1 )


###############################################################################
# Functions

# Экспанента в "зоне шума". Работает как деликатный шумодав, не даёт сигналу из
# рабочего диапазона резко выстрелить из ниоткуда
def y1( x ):
   # bend регулирует "прогиб" экспаненты
   bend = 2
   # adjust компенсирует подъем графика в 0, так, чтобы 0 по y и 0 по x совпадали
   adjust_1 = nf * ( m.exp( -bend ))
   # компенсирует опускание графика в nf, так, чтобы y(nf) = nf
   k = ( nf + adjust_1 ) / nf

   #return nf * k * ( m.exp((x - nf) / nf*bend) ) - adjust_1
   return x


# Предрасчёт параметров для y2_sin(x)
x1 = m.hypot(nf,nf)
x2 = m.hypot(il,il)
a = -m.pi/4
sina=m.sin(a)
cosa=m.cos(a)
scale = il / 3

def sin_calc_and_rotate( x ):
    y = scale * m.sin( m.pi*(x-x1)/(x2-x1))
    y_ = -x*sina + y*cosa
    x_ =  x*cosa + y*sina
    return (x_, y_)

def y2_sin( x ):
    x_hip  = m.ceil( m.hypot(x,x) )
    for i in range(x_hip, m.ceil(x2)):
        (x_, y_) = sin_calc_and_rotate( i )
        if( x_ >= x ):
            return y_

# Основной рабочий диапазон. Здесь создаётся компрессия сигнала.
def y2( x ):
    return y2_sin(x)


# Зона выше порога, в которой работает спад по колоколу. Сюда входной
# сигнал может попать только после предварительного растягивания
def y3( x ):
    # Сигма это мэджик намбер. Подобран на глазок по графику
    sigma = 2000000
    npd = m.exp( - ((x-il)**2) / sigma )
    return il * npd

# Создаёт .mif фаил, засовывает туда MIF_HEADER, затем значения по адресам
def create_rom_image( fname, y ):
    f = open( fname, "w" )
    f.write("%s" % MIF_HEADER)
    f = open( fname, "a" )
    f.write("%s\n" % "CONTENT BEGIN")
    for i in range( len( y ) ):
        wstr = "{:04x}".format(i) + "    :    " + "{:04x}".format( int(y[i])) + ";"
        f.write("%s\n" % wstr)
    f.write("%s\n" % "END;")

# Рисует графики
def draw_plot( x, y ):
        ax = plt.subplot(111)

        # Создаём кривые на графике
        ax.plot( x, color="blue", linestyle="solid", linewidth=1.5, label="100% dry")
        ax.plot( y, color="red",  linestyle="solid", linewidth=1.5, label="100% wet")
        #ax.plot( z, color="orange", linestyle="solid", linewidth=1, label="mix" )

        # Без этой опции может сделать подпись к шкалам трудночитаемой
        ax.ticklabel_format(useOffset=False)
        ax.grid(True)

        # Задаём явно диапазоны значений
        ax.set_xlim([0, N])
        ax.set_ylim([0, N])
        # Делает график квадратным
        ax.set_aspect('equal', adjustable='box')

        # Плотный блок кода ниже просто создаёт красивые цветные квадратики с
        # альфа квадратиков (транспарентность)
        a = 0.1
        # Регион выше лимитера
        plt.axvspan(xmin=il, xmax=N, ymin=0, ymax=1, color="grey", alpha = a )
        plt.axvspan(xmin=0, xmax=il, ymin=il/N, ymax=1, color="grey", \
                   alpha = a, label="zone above limiter")
        # Область пиков при самой жесткой атаке
        plt.axvspan(xmin=pk, xmax=il, ymin=0, ymax=il/N, color="red", alpha = a)
        plt.axvspan(xmin=0, xmax=pk, ymin=pk/N, ymax=il/N, color="red", \
                alpha = a, label="top peaks")
        # Область плотненького валилова
        plt.axvspan(xmin=hs, xmax=pk, ymin=0, ymax=pk/N, color="orange", alpha = a )
        plt.axvspan(xmin=0, xmax=hs, ymin=hs/N, ymax=pk/N, color="orange", \
                alpha = a, label="hard strum")
        # Область девичей возни 0.5 медиатором
        plt.axvspan(xmin=0, xmax=hs, ymin=0, ymax=hs/N, color="darkgreen", \
                alpha = a,label="soft strum")
        # Едва ковыряем
        plt.axvspan(xmin=0, xmax=ss, ymin=0, ymax=ss/N, color="lightgreen", \
                alpha = 0.5, label="quietest notes")
        # Там уже только шумы
        plt.axvspan(xmin=0, xmax=nf, ymin=0, ymax=nf/N, color="lightgrey", \
                alpha = 1, label="zone under noise floor")

        plt.legend()
        plt.show()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='A script that creates ROM with \
            overdrive/distortion transfer function in .mif image', prefix_chars='-')

    parser.add_argument('-f', metavar='file', type=str, help='fname (e.g. my_crazy_overdive.mif)')
    parser.add_argument('-s', action='store_true')

    args = parser.parse_args()
    parsed_args = vars(args)

    x = [0] * N
    y = [0] * N
    z = [0] * N

    # Создаём линейную последовательность значений
    for i in range(0,N):
        x[i] = i

    # Формируем трансферную функцию wet-сигнала из трёх кусков
    for i in range(0,N):
        if( i < nf ):
             y[i] = y1(x[i])
        else:
             if( i < il ):
                  y[i] = y2(x[i])
             else:
                  y[i] = y3(x[i])

    # Имитация кроссфейдера, предполагаемого в дизайне для вспомогательных целей
    for i in range(0,N):
        a_x = 0.5
        a_y =  1 - a_x
        if ( i < il ):
            z[i] = a_x * x[i] + a_y * y[i]
        else:
            z[i] = y[i]

    if parsed_args["f"] is not None:
        create_rom_image( parsed_args["f"], y )


    if parsed_args["s"] is True:
        draw_plot( x, y )
