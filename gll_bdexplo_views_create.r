#!/usr/bin/rebol -qs
rebol	[
	Title:   "Création des vues de bdexplo"
	Name:    gll_bdexplo_views_create.r
	Version: 1.0.0
	Date:    "5-Aug-2013/17:53:46"
	Author:  "Pierre Chevalier"
	License: {
This file is part of GeolLLibre software suite: FLOSS dedicated to Earth Sciences.
###########################################################################
##          ____  ___/_ ____  __   __   __   _()____   ____  _____       ##
##         / ___\/ ___// _  |/ /  / /  / /  /  _/ _ \ / __ \/ ___/       ##
##        / /___/ /_  / / | / /  / /  / /   / // /_/_/ /_/ / /_          ##
##       / /_/ / /___|  \/ / /__/ /__/ /___/ // /_/ / _, _/ /___         ##
##       \____/_____/ \___/_____/___/_____/__/_____/_/ |_/_____/         ##
##                                                                       ##
###########################################################################
  Copyright (C) 2013 Pierre Chevalier <pierrechevaliergeol@free.fr>
 
    GeolLLibre is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>
    or write to the Free Software Foundation, Inc., 51 Franklin Street, 
    Fifth Floor, Boston, MA 02110-1301, USA.
    See LICENSE file.
}
]


;	 _________
;	< bdexplo >
;	 ---------
;	        \   ^__^
;	         \  (xx)\_______
;	            (__)\       )\/\
;	             U  ||----w |
;	                ||     ||
;	

do load to-file system/options/home/bin/gll_routines.r	; Récupération des routines et préférences et connexion à la base
insert db "BEGIN TRANSACTION;"

;# on commence à fabriquer un gros texte en sql, qu'on fera tourner à la fin: {{{
sql_string: {
BEGIN TRANSACTION;
} ; fait doublon, mais c'est pour le moment du débogage où l'on ne fait qu'afficher le SQL résultant
;}}}

; on y met d'abord les vues homonymes des tables dans le premier schéma: {{{
;# -- 1. les vues homonymes des tables, dans le premier schéma dans l'ordre de recherche, en restreignant à l'opération active: {{{

;# La liste des tables pour lesquelles on veut faire une vue homonyme dans le schéma utilisateur:
;comment [ {{{ } } } 
;tables_for_view_join_operationid = [
;'ancient_workings'        ,
;'dh_collars'              ,
;'dh_collars_program'      ,
;'dh_density'              ,
;'dh_devia'                ,
;'dh_litho'                ,
;'dh_mineralised_intervals',
;#'dh_sampling'             ,
;'dh_sampling_grades'      ,
;'dh_struct'               ,
;'dh_tech'                 ,
;'field_observations'      ,
;'field_photos'            ,
;'geoch_ana'               ,
;'geoch_sampling'          ,
;'geoch_sampling_grades'   ,
;'grade_ctrl'              ,
;'lab_ana_batches'         ,
;'lab_ana_results'         ,
;'lab_analysis_icp'        ,
;'occurrences'             ,
;'qc_sampling'             ,
;'qc_standards'            ,
;'rock_ana'                ,
;'rock_sampling'           ,
;'shift_reports'           ,
;'topo_points'
;]
;] ; }}}

tables_for_view_join_operationid: []
tables_public: run_query "SELECT tablename FROM pg_tables WHERE schemaname = 'public';"
; on enlève les tables qui n'ont pas à être VIEWées:
foreach t tables_public [ append tables_for_view_join_operationid to-string t ]
tables_indesirables: ["dh_nb_samples" "dh_collars_lengths" "spatial_ref_sys" "geometry_columns" "operations" "operation_active" "units" "conversions_oxydes_elements" "doc_bdexplo_table_categories" "doc_bdexplo_tables_descriptions" ]
tables_for_view_join_operationid: (exclude tables_for_view_join_operationid tables_indesirables)

; pour voir les tables concernées rapidos:
;foreach t tables_for_view_join_operationid [
;print rejoin ["TABLE public." t ";"]
;]

;#}}}

;# on fabrique le gros texte en sql:{{{

foreach tablename tables_for_view_join_operationid [
	append sql_string rejoin ["CREATE VIEW " tablename " AS SELECT " tablename ".* FROM " tablename " JOIN operation_active ON " tablename ".opid = operation_active.opid;" newline]
	]

;#}}}
;# --}}}

;# À partir de l'instruction sql ainsi commencée, on l'agrège maintenant, avec un gros tas de requêtes déjà faites:
; 2018_08_26__20_14_24 => no, rather store these views definition into a separate plain SQL file.
;# Voilà, le sql est fabriqué.


;# ...que l'on runne ensuite:
;# (cancellé, pour le moment, par prudence: on montre juste le SQL)
;print to-string sql_string
; insert db to-string sql_string
; => marche pas, cf. Doc

close  db


ligne_cmd: rejoin [{echo "} sql_string {" | psql -X -d } dbname { -h } dbhost { -U } user ]


either ( confirm "Run the generated script?" ) [
	call/wait ligne_cmd ]
	[
	; Prudemment, on ne runne pas, on affiche juste:
	; print ligne_cmd
	; Mieux, on génère un script à runner:
	script: %tt_gll_bdexplo_views_create.sh 
	write script ligne_cmd
	print rejoin [newline "Bdexplo views creation script generated: " to-string script newline "to run it:" newline "sh " to-string script newline]
	]
;###########################################################
