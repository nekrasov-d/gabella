#!/bin/python3
# Copyright (C) 2021 Dmitriy Nekrasov
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#
# XXX: add annotation
#

import matplotlib.pyplot as plt
import math as m
import argparse

###############################################################################
# Parameters

N = 255

###############################################################################
# MIF header / annotation

MIF_HEADER = \
"-- This file is automatically generated by gen_sinus.py program\
\n\
\nWIDTH=16;\
\nDEPTH=%d;\
\nADDRESS_RADIX=HEX;\
\nDATA_RADIX=HEX;\
\n\n" % ( N+1 )


# Создаёт .mif фаил, засовывает туда MIF_HEADER, затем значения по адресам
def create_rom_image( fname, y ):
    f = open( fname, "w" )
    f.write("%s" % MIF_HEADER)
    f = open( fname, "a" )
    f.write("%s\n" % "CONTENT BEGIN")
    for i in range( len( y ) ):
        wstr = "{:04x}".format(i) + "    :    " + "{:04x}".format(y[i]) + ";"
        f.write("%s\n" % wstr)
    f.write("%s\n" % "END;")

# Рисует графики
def draw_plot( x, y ):
        ax = plt.subplot(111)

        # Создаём кривые на графике
        #ax.plot( x, color="blue", linestyle="solid", linewidth=1.5, label="100% dry")
        ax.plot( y, color="red",  linestyle="solid", linewidth=1.5, label="100% wet")
        #ax.plot( z, color="orange", linestyle="solid", linewidth=1, label="mix" )

        # Без этой опции может сделать подпись к шкалам трудночитаемой
        ax.ticklabel_format(useOffset=False)
        ax.grid(True)

        # Задаём явно диапазоны значений
        #ax.set_xlim([0, N])
        ax.set_ylim([-N, N])
        # Делает график квадратным
        ax.set_aspect('equal', adjustable='box')

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

    # Создаём линейную последовательность значений
    for i in range(0,N):
        x[i] = i

    for i in range(0,N):
        sin = m.ceil(10000*m.sin(x[i]*2*m.pi / N))

        if(sin < 0):
            sin = 0xffff + sin

        y[i] = sin

    if parsed_args["f"] is not None:
        create_rom_image( parsed_args["f"], y )

    if parsed_args["s"] is True:
        draw_plot( x, y )
