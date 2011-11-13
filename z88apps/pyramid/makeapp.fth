\ *************************************************************************************
\
\ Puzzle Of The Pyramid (c) Garry Lancaster, 1998-1999
\
\ Puzzle Of The Pyramid is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ Puzzle Of The Pyramid is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with Puzzle
\ Of The Pyramid; see the file COPYING. If not, write to the
\ Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\
\ *************************************************************************************

\ Make file for "Puzzle Of The Pyramid" application

S" pyramid-app.fth" INCLUDED
S" appgen.fth" INCLUDED
S" pyramid-app.dor" INCLUDED

S" pyramid-std" STANDALONE	\ create standalone application
S" pyramid-cli" CLIENT		\ create client application

