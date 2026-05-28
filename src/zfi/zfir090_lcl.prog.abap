*&---------------------------------------------------------------------*
*& 包含               ZFIR092_LCL
*&---------------------------------------------------------------------*



CLASS player DEFINITION DEFERRED.
TYPES: ty_player TYPE REF TO player.
CLASS player DEFINITION.
  PUBLIC SECTION.
    TYPES:BEGIN OF ts_s_find,
            rclnt  TYPE mandt,                              "mod-0001
            rldnr  TYPE fins_ledger,                        "mod-0001
            docln  TYPE docln6,                             "mod-0001
            rbukrs TYPE bukrs,         "公司代码
            lifnr  TYPE lifnr,         "供应商编码
            name1  TYPE txt120,      "供应商名称
            gjahr  TYPE gjahr,         "年度
            belnr  TYPE belnr_d,       "凭证编码
            bktxt  TYPE bktxt,         "摘要
            sgtxt  TYPE sgtxt,         "文本
            budat  TYPE budat,         "过账日期
            poper  TYPE poper,         "期间
            racct  TYPE racct,         "总账科目
            txt50  TYPE txt50_skat,    "科目描述
            rwcur  TYPE fins_currw,    " 交易货币  usd    原币 币种
            rhcur  TYPE fins_currh,    " 公司代码货币   人民币 币种
            wsl    TYPE fins_vwcur12,  " 原币 金额
            hsl    TYPE fins_vhcur12,  "人民币 金额
            drcrk  TYPE shkzg,         "借贷标识
            ebeln  TYPE ebeln,         "采购订单
            delf   TYPE abap_bool,     "删除标记
            ddtext TYPE dd07d-ddtext,    "辅助项类别
            fzx    TYPE dd07d-ddtext,    "辅助项
            fzxms  TYPE dd07d-ddtext,    "辅助项描述
            mwskz  TYPE mwskz,           "税码
            rfarea TYPE fkber,           "职能范围
            buzei  TYPE buzei,           "会计凭证中的行项目编号
          END OF ts_s_find.
    TYPES:tt_find TYPE TABLE OF ts_s_find.


    TYPES:BEGIN OF ts_s_alvsum,
            rbukrs    TYPE bukrs,           "公司代码
            lifnr     TYPE lifnr,           "供应商编码
            name1     TYPE txt120,          "供应商名称
            gork      TYPE txt20,           "供应商还是客商
            racct     TYPE racct,           "总账科目
            txt50     TYPE txt50_skat,      "科目描述
            ddtext    TYPE dd07d-ddtext,    "辅助项类别
            fzxlbms   TYPE string,
            fzx       TYPE dd07d-ddtext,    "辅助项
            fzxms     TYPE dd07d-ddtext,    "辅助项描述
            rwcur     TYPE fins_currw,      "交易货币  usd    原币 币种
            rhcur     TYPE fins_currh,      "公司代码货币   人民币 币种
            qcybed    TYPE fins_vwcur12,    "期初原币额度   借方期初
            qcbbed    TYPE fins_vhcur12,    "期初本币额度   借方期初
            drcrk     TYPE shkzg,           "期初借方标识
            qcdfybed  TYPE fins_vwcur12,    "期初原币额度   贷方期初
            qcdfbbed  TYPE fins_vhcur12,    "期初本币额度   贷方期初
            drdfcrk   TYPE shkzg,           "期初贷方标识
*          add new field begin
            qcybyenew TYPE  fins_vwcur12,  "期初原币余额
            qcbbyenew TYPE  fins_vhcur12,  "期初本币余额
            qcjdbiaos TYPE shkzg,          "期初借贷标识
*          add new  field end
            wsl       TYPE fins_vwcur12,    "本期原币 金额   借方
            hsl       TYPE fins_vhcur12,    "本期人民币 金额 借方
            dkfwsl    TYPE fins_vwcur12,   "本期原币金额   贷方
            dkfhsl    TYPE fins_vhcur12,    "本期人民币金额  贷方
            drcrkd    TYPE shkzg,           "当前数据的 借贷标识   借方/贷方
            qmybed    TYPE fins_vwcur12,    "期末原币额度
            qmbbed    TYPE fins_vwcur12,    "期末本币额度
          END OF ts_s_alvsum.

    TYPES:tt_alv_sum TYPE TABLE OF ts_s_alvsum.
    TYPES:ts_alv_sum TYPE ts_s_alvsum.
    CLASS-DATA: ls_alv_sum TYPE ts_alv_sum.
    CLASS-DATA: lt_alv_sum TYPE tt_alv_sum.
    CLASS-DATA: lt_alv_sum_hz TYPE tt_alv_sum.
    DATA: gr_table TYPE REF TO cl_salv_table.
    DATA: gr_columns TYPE REF TO cl_salv_columns_table.
    DATA: gr_column TYPE REF TO cl_salv_column_table.
    DATA: gr_layout TYPE REF TO cl_salv_layout.
    DATA: gs_program TYPE salv_s_layout_key.
    DATA: gr_selection TYPE REF TO cl_salv_selections.



    METHODS write_player_detailssum."根据辅助项汇总，根据原币+本币汇总
    METHODS write_player_detailssum2."不根据辅助项汇总，根据原币+本币汇总
    METHODS write_player_detailssum3."不根据辅助项汇总，根据本币汇总
    METHODS  write_player_show_sum_alv
      IMPORTING it_alv TYPE tt_alv_sum.

    METHODS constructor IMPORTING iv_tbname    TYPE tabname
                                  iv_condition TYPE text10.
    CLASS-METHODS: display_list_of_players.


*    METHODS:
*      on_hotspot_click FOR EVENT link_click OF cl_salv_events_table IMPORTING row column.

  PRIVATE SECTION.


    DATA:lt_find      TYPE TABLE OF ts_s_find,
         ls_find      TYPE ts_s_find,
         lt_findk     TYPE TABLE OF ts_s_find,
         ls_findk     TYPE ts_s_find,
         lt_findbug   TYPE TABLE OF ts_s_find,
         ls_findbug   TYPE ts_s_find,
         "   ls_alvplay   TYPE ts_s_alvplay,
         lv_tabname   TYPE tabname,
         lv_condition TYPE text10,
         lv_where     TYPE string.

    DATA:lt_poper TYPE RANGE OF acdoca-poper.

    DATA:lt_racct TYPE RANGE OF acdoca-racct.

    DATA:
      lv_statement  TYPE string,
      lr_result     TYPE REF TO data,
      lr_resultk    TYPE REF TO data,
      lr_resultbug  TYPE REF TO data,
      lo_conn       TYPE REF TO cl_sql_connection,
      lo_statement  TYPE REF TO cl_sql_statement,
      lo_result_set TYPE REF TO cl_sql_result_set,
      lx_sql        TYPE REF TO cx_sql_exception.


    TYPES:BEGIN OF ts_s_view,
            rbukrs TYPE bukrs,
            lifnr  TYPE lifnr,         "供应商编码
            racct  TYPE racct,
            gjahr  TYPE gjahr,         "年度
            poper  TYPE poper,         "期间
            budat  TYPE budat,         "
            rwcur  TYPE fins_currw,
            rhcur  TYPE fins_currh,
            drcrk  TYPE shkzg,         "借贷标识
            wsl    TYPE wrbtr,    "本期原币 金额   借方
            hsl    TYPE fins_vhcur12,    "本期人民币 金额 借方


            mwskz  TYPE mwskz,           "税码
            rfarea TYPE fkber,           "职能范围
            ddtext TYPE dd07d-ddtext,    "辅助项类别
            fzx    TYPE dd07d-ddtext,    "辅助项
            fzxms  TYPE dd07d-ddtext,    "辅助项描述
          END OF ts_s_view.
    TYPES:tt_view TYPE TABLE OF ts_s_view,
          ts_view TYPE ts_s_view.

    CLASS-DATA: players_list TYPE STANDARD TABLE OF ty_player.
ENDCLASS.


CLASS player IMPLEMENTATION.
  METHOD constructor.

    GET REFERENCE OF me->lt_find INTO me->lr_result.
    LOOP AT s_monat INTO DATA(ls_monat).
      me->lt_poper = VALUE #( BASE me->lt_poper (  sign = 'I' option = 'EQ' low = |0| && ls_monat-low high = |0| && ls_monat-high ) ).
    ENDLOOP.

    lv_condition = iv_condition.

    me->lv_tabname = iv_tbname.

**mod-0001 delete
*    me->lv_where =  | gjahr <= '{ p_gjahr }' and blart <> '' and  rclnt = '{ sy-mandt }'  and BLART  <> 'X'   and XREVERSING <> 'X'  and XREVERSED <> 'X'and XTRUEREV <> 'X'| .
**mod-0001 add
    me->lv_where =  | gjahr <= '{ p_gjahr }' and blart <> '' and  rclnt = '{ sy-mandt }' and rldnr = '0L' |  .

*   转换range变成where条件   begin
    TRY.
        DATA(lv_where_clause) = cl_shdb_seltab=>combine_seltabs(
                                 it_named_seltabs = VALUE #(
                                   ( name = 'RACCT'  dref = REF #( s_racct[] ) )
*                                   ( name = 'LIFNR'  dref = REF #( s_lifnr[] ) )
                                   ( name = 'RBUKRS' dref = REF #( s_bukrs[] ) )
                                                            )   ).
        me->lv_where = me->lv_where && | AND { lv_where_clause }|.
      CATCH cx_shdb_exception INTO DATA(lr_ex).
        WRITE: lr_ex->get_text( ).
    ENDTRY.
*   转换range变成where条件   end

*组合好sql语句  begin
*    me->lv_where = me->lv_where && | AND { lv_where_clause }|.
    me->lv_statement = | SELECT rclnt, rldnr, docln,  rbukrs, lifnr, '' as name1, gjahr, | &&
                       | belnr, '' as bktxt, sgtxt, budat, poper, | &&
                       | racct, '' as TXT50, rwcur, rhcur, wsl, hsl, drcrk, ebeln, '' as DELF, | &&
                       | '' as ddtext, '' as fzx, '' as fzxms, mwskz, rfarea ,  buzei | &&
                       | from { me->lv_tabname }| &&
                       | where { me->lv_where }|.
*组合好sql语句  end


    TRY.
**n调用SQL-Connection方法，连接到数据库
        lo_conn = cl_sql_connection=>get_connection( ).
**n調用SQL-Statement方法，创建SQL对毎
        lo_statement = lo_conn->create_statement( ).
*"調用SQL-query方还，执行SQL语句
        lo_result_set = lo_statement->execute_query( me->lv_statement ).
        "调用SQL-set_param_table方法，指定用哪个内表来记录返回结果
        lo_result_set->set_param_table( me->lr_result ).

*        CATCH cx_parameter_invalid. " Superclass for Parameter Error
*往取数据集的下一组数据到内表
        lo_result_set->next_package( ).
*”褥到结果后，关闭数据棄
        lo_result_set->close( ).
*”打印内表
*        cl_demo_output=>display_data( me->lt_find ).

*”错误处理，如SQL有误，则在此处报出log,而不会导致系统崩溃(short dump )
      CATCH cx_sql_exception INTO lx_sql.
        WRITE: lx_sql->get_text( ).
    ENDTRY.


***捞取客户数据

    GET REFERENCE OF me->lt_findk INTO me->lr_resultk.
*    LOOP AT s_monat INTO DATA(ls_monat).
*      me->lt_poper = VALUE #( BASE me->lt_poper (  sign = 'I' option = 'EQ' low = |0| && ls_monat-low high = |0| && ls_monat-high ) ).
*    ENDLOOP.

    CLEAR:me->lv_where.

    lv_condition = iv_condition.

    me->lv_tabname = iv_tbname.

*mod-0001 delete
*    me->lv_where =  | gjahr <= '{ p_gjahr }' and blart <> '' and  rclnt = '{ sy-mandt }'  and BLART  <> 'X' and XREVERSING <> 'X' and XREVERSED <> 'X'and XTRUEREV <> 'X' | .
*mod-0001 add
    me->lv_where =  | gjahr <= '{ p_gjahr }' and blart <> '' and  rclnt = '{ sy-mandt }' and rldnr = '0L' | .

*   转换range变成where条件   begin
    CLEAR:lv_where_clause.
    TRY.
        lv_where_clause = cl_shdb_seltab=>combine_seltabs(
                                 it_named_seltabs = VALUE #(
                                   ( name = 'RACCT'  dref = REF #( s_racct[] ) )
*                                   ( name = 'KUNNR'  dref = REF #( s_kunnr[] ) )
                                   ( name = 'RBUKRS' dref = REF #( s_bukrs[] ) )
                                                            )   ).
        me->lv_where = me->lv_where && | AND { lv_where_clause }|.
      CATCH cx_shdb_exception INTO lr_ex.
        WRITE: lr_ex->get_text( ).
    ENDTRY.
*   转换range变成where条件   end

*组合好sql语句  begin
*    me->lv_where = me->lv_where && | AND { lv_where_clause }|.
    me->lv_statement = | SELECT rclnt, rldnr, docln,  rbukrs, kunnr as lifnr, '' as name1, gjahr, | &&
                       | belnr, '' as bktxt, sgtxt, budat, poper, | &&
                       | racct, '' as TXT50, rwcur, rhcur, wsl, hsl, drcrk, ebeln, '' as DELF ,| &&
                        | '' as ddtext, '' as fzx, '' as fzxms, mwskz, rfarea,  buzei | &&

                       | from { me->lv_tabname }| &&
                       | where { me->lv_where }|.
*组合好sql语句  end

    TRY.
**n调用SQL-Connection方法，连接到数据库
        lo_conn = cl_sql_connection=>get_connection( ).
**n調用SQL-Statement方法，创建SQL对毎
        lo_statement = lo_conn->create_statement( ).
*"調用SQL-query方还，执行SQL语句
        lo_result_set = lo_statement->execute_query( me->lv_statement ).
        "调用SQL-set_param_table方法，指定用哪个内表来记录返回结果
        lo_result_set->set_param_table( me->lr_resultk ).
*往取数据集的下一组数据到内表
        lo_result_set->next_package( ).
*”褥到结果后，关闭数据棄
        lo_result_set->close( ).
*”打印内表
*        cl_demo_output=>display_data( me->lt_find ).

*”错误处理，如SQL有误，则在此处报出log,而不会导致系统崩溃(short dump )
      CATCH cx_sql_exception INTO lx_sql.
        WRITE: lx_sql->get_text( ).
    ENDTRY.

    LOOP AT  me->lt_findk ASSIGNING FIELD-SYMBOL(<ls_findk>) WHERE racct = '2202030100'.
*     <ls_findk>-delf = abap_true.
      DATA(lv_findbug) = 'X'.
      EXIT.
    ENDLOOP.

    IF lv_findbug = 'X'.
      DELETE me->lt_findk WHERE racct = '2202030100'.

      GET REFERENCE OF me->lt_findbug INTO me->lr_resultbug.

      lv_condition = iv_condition.

      me->lv_tabname = iv_tbname.

      CLEAR:me->lv_where.

      me->lv_where =  | gjahr <= '{ p_gjahr }' and blart <> '' | &&
                      |and  rclnt = '{ sy-mandt }'  |  &&
                      |and  lifnr = '' | &&
                      |and  racct = '2202030100' and rldnr = '0L' |.
      CLEAR:lv_where_clause.

*   转换range变成where条件   begin
      TRY.
          lv_where_clause = cl_shdb_seltab=>combine_seltabs(
                                   it_named_seltabs = VALUE #(
                                     ( name = 'RACCT'  dref = REF #( s_racct[] ) )
*                                     ( name = 'LIFNR'  dref = REF #( s_lifnr[] ) )
                                     ( name = 'RBUKRS' dref = REF #( s_bukrs[] ) )
                                                              )   ).
          me->lv_where = me->lv_where && | AND { lv_where_clause }|.
        CATCH cx_shdb_exception INTO lr_ex.
          WRITE: lr_ex->get_text( ).
      ENDTRY.
*   转换range变成where条件   end

*组合好sql语句  begin
*    me->lv_where = me->lv_where && | AND { lv_where_clause }|.
      CLEAR:me->lv_statement.
      me->lv_statement = | SELECT rclnt, rldnr, docln,  rbukrs, lifnr, '' as name1, gjahr, | &&
                         | belnr, '' as bktxt, sgtxt, budat, poper, | &&

                         | racct, '' as TXT50, rwcur, rhcur, wsl, hsl, drcrk, ebeln, '' as DELF ,| &&
                         | '' as ddtext, '' as fzx, '' as fzxms, mwskz, rfarea , buzei | &&
                         | from { me->lv_tabname }| &&
                         | where { me->lv_where }|.
*组合好sql语句  end

      TRY.
**n调用SQL-Connection方法，连接到数据库
          lo_conn = cl_sql_connection=>get_connection( ).
**n調用SQL-Statement方法，创建SQL对毎
          lo_statement = lo_conn->create_statement( ).
*"調用SQL-query方还，执行SQL语句
          lo_result_set = lo_statement->execute_query( me->lv_statement ).
          "调用SQL-set_param_table方法，指定用哪个内表来记录返回结果
          lo_result_set->set_param_table( me->lr_resultbug ).
*往取数据集的下一组数据到内表
          lo_result_set->next_package( ).
*”褥到结果后，关闭数据棄
          lo_result_set->close( ).
*”打印内表
*        cl_demo_output=>display_data( me->lt_find ).

*”错误处理，如SQL有误，则在此处报出log,而不会导致系统崩溃(short dump )
        CATCH cx_sql_exception INTO lx_sql.
          WRITE: lx_sql->get_text( ).
      ENDTRY.

      DATA:lt_acdocat TYPE TABLE OF acdoca.

      SELECT FROM @me->lt_findbug AS a ##ITAB_KEY_IN_SELECT
        INNER JOIN acdoca AS b
        ON a~rldnr = b~rldnr AND
           a~rbukrs = b~rbukrs AND
           a~gjahr  = b~gjahr  AND
           a~belnr  = b~belnr
        FIELDS
        b~rclnt,
        b~rldnr,
        b~rbukrs,
        b~gjahr,
        b~belnr,
        b~docln,
        b~lifnr
        WHERE b~lifnr <> ''
        INTO TABLE @DATA(lt_findlifnr).
      SORT lt_findlifnr BY rclnt rldnr rbukrs gjahr belnr.
      DELETE ADJACENT DUPLICATES FROM lt_findlifnr COMPARING rclnt  rldnr rbukrs gjahr belnr.

      LOOP AT me->lt_findbug ASSIGNING FIELD-SYMBOL(<ls_findbug>).
        READ TABLE lt_findlifnr INTO DATA(ls_findlifnr) WITH KEY rclnt = <ls_findbug>-rclnt
                                                                 rldnr = <ls_findbug>-rldnr
                                                                 rbukrs = <ls_findbug>-rbukrs
                                                                 gjahr = <ls_findbug>-gjahr
                                                                 belnr = <ls_findbug>-belnr
                                                                 BINARY SEARCH.
        IF sy-subrc = 0.
          <ls_findbug>-lifnr = ls_findlifnr-lifnr.
        ENDIF.
      ENDLOOP.

*      DELETE me->lt_findbug WHERE lifnr NOT IN s_lifnr.

    ENDIF.

    APPEND me TO players_list.
  ENDMETHOD.




  METHOD write_player_show_sum_alv.

    DATA:
      lt_comps TYPE abap_compdescr_tab,
      lr_struc TYPE REF TO cl_abap_structdescr.
    FIELD-SYMBOLS:<fs_comps> LIKE LINE OF lt_comps.
    DATA:lo_salv_msg       TYPE REF TO cx_salv_msg,
         lo_salv_not_found TYPE REF TO cx_salv_not_found,
         lv_msg            TYPE string.

    lr_struc ?= cl_abap_typedescr=>describe_by_data( me->ls_alv_sum ).
    lt_comps = lr_struc->components.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = gr_table
          CHANGING
            t_table      = me->lt_alv_sum ).
      CATCH cx_salv_msg INTO lo_salv_msg.
        lv_msg = lo_salv_msg->get_text( ).
        MESSAGE lv_msg TYPE 'E'.
    ENDTRY.

************************标题
    DATA: lo_display TYPE REF TO cl_salv_display_settings.
    DATA: lv_title   TYPE  lvc_title.
    lv_title = '科目余额表' && p_gjahr && '年' && s_monat-low &&  '-' && s_monat-high && '月'.
    lo_display = gr_table->get_display_settings( ).
    lo_display->set_list_header( lv_title ).
*********************************

    TRY.
        gr_columns = gr_table->get_columns( ).
        gr_columns->set_optimize( 'X' ).
        LOOP AT lt_comps ASSIGNING <fs_comps>.
          gr_column ?= gr_columns->get_column( <fs_comps>-name ).

          IF <fs_comps>-name = 'QCDFYBED' OR <fs_comps>-name = 'QCYBYENEW' OR <fs_comps>-name =  'WSL' OR <fs_comps>-name =  'DKFWSL' OR <fs_comps>-name =  'QMYBED'.
            IF c_zhbwb = 'X'.
              gr_column->set_technical( abap_true ).
            ENDIF.
          ENDIF.
          IF <fs_comps>-name = 'DDTEXT' OR <fs_comps>-name = 'FZXLBMS' OR <fs_comps>-name =  'FZX' OR <fs_comps>-name =  'FZXMS' .
            IF c_fzx = ''.
              gr_column->set_technical( abap_true ).
            ENDIF.
          ENDIF.
          IF <fs_comps>-name = 'RWCUR'.
            " IF c_zhbwb = 'X' AND c_fzx = ''.
            IF c_zhbwb = 'X'.
              gr_column->set_technical( abap_true ).
            ENDIF.
          ENDIF.

          CASE <fs_comps>-name.

            WHEN 'LIFNR' OR 'NAME1' OR 'GORK'  OR ' DRCRK' OR 'DRDFCRK'
               OR 'QCYBED' OR 'QCBBED'  OR 'QCDFYBED' OR 'QCDFBBED'  OR 'DRCRK'  OR 'DDTEXT'.
              "  OR  'MWSKZ ' OR 'RFAREA'  OR 'FKBTX ' OR ' KBETR'.
              gr_column->set_technical( abap_true ).
            WHEN 'RACCT'. "总账科目
              gr_column->set_long_text( '会计科目' ).
              gr_column->set_medium_text( '会计科目').
              gr_column->set_short_text( '会计科目').
              gr_column->set_output_length( 15 ).

            WHEN 'TXT50'. "总账科目
              gr_column->set_long_text( '会计科目描述' ).
              gr_column->set_medium_text( '会计科目描述').
              gr_column->set_short_text( '会计科目描述').
              gr_column->set_output_length( 15 ).

            WHEN 'DDTEXT'. "辅助项类别
              gr_column->set_long_text( '辅助项类别' ).
              gr_column->set_medium_text( '辅助项类别').
              gr_column->set_short_text( '辅助项类别').
              gr_column->set_output_length( 15 ).

            WHEN 'FZXLBMS'. "辅助项类别
              gr_column->set_long_text( '辅助项类别' ).
              gr_column->set_medium_text( '辅助项类别').
              gr_column->set_short_text( '辅助项类别').
              gr_column->set_output_length( 15 ).


            WHEN 'FZX'. "辅助项
              gr_column->set_long_text( '辅助项' ).
              gr_column->set_medium_text( '辅助项').
              gr_column->set_short_text( '辅助项').
              gr_column->set_output_length( 15 ).

            WHEN 'FZXMS'. "辅助项
              gr_column->set_long_text( '辅助项描述' ).
              gr_column->set_medium_text( '辅助项描述').
              gr_column->set_short_text( '辅助项描述').
              gr_column->set_output_length( 15 ).

            WHEN 'RWCUR'. "原币
              gr_column->set_long_text( '原币货币' ).
              gr_column->set_medium_text( '原币货币').
              gr_column->set_short_text( '原币货币').
              gr_column->set_output_length( 15 ).
            WHEN 'RHCUR'. "本币
              gr_column->set_long_text( '本币货币' ).
              gr_column->set_medium_text( '本币货币').
              gr_column->set_short_text( '本币货币').
              gr_column->set_output_length( 15 ).

*            WHEN 'QCYBED'. "期初原币金额（借方）
*              gr_column->set_long_text( '期初原币金额（借方）' ).
*              gr_column->set_medium_text( '期初原币金额（借方）').
*              gr_column->set_short_text( '期初原币金额（借方）').
*              gr_column->set_output_length( 15 ).
*            WHEN 'QCBBED'. "期初本币金额（借方）
*              gr_column->set_long_text( '期初本币金额（借方）' ).
*              gr_column->set_medium_text( '期初本币金额（借方）').
*              gr_column->set_short_text( '期初本币金额（借方）').
*              gr_column->set_output_length( 15 ).
*
*            WHEN 'DRCRK'. "期初借方标识
*              gr_column->set_long_text( '期初借方标识' ).
*              gr_column->set_medium_text( '期初借方标识').
*              gr_column->set_short_text( '期初借方标识').
*              gr_column->set_output_length( 15 ).
*
*            WHEN 'QCDFYBED'. "期初原币金额（贷方）
*              gr_column->set_long_text( '期初原币金额（贷方）' ).
*              gr_column->set_medium_text( '期初原币金额（贷方）').
*              gr_column->set_short_text( '期初原币金额（贷方）').
*              gr_column->set_output_length( 15 ).
*
*            WHEN 'QCDFBBED'. "期初本币金额（贷方）
*              gr_column->set_long_text( '期初本币金额（贷方）' ).
*              gr_column->set_medium_text( '期初本币金额（贷方）').
*              gr_column->set_short_text( '期初本币金额（贷方）').
*              gr_column->set_output_length( 15 ).
*            WHEN 'DRDFCRK'. "期初贷方标识
*              gr_column->set_long_text( '期初贷方标识' ).
*              gr_column->set_medium_text( '期初贷方标识').
*              gr_column->set_short_text( '期初贷方标识').
*              gr_column->set_output_length( 15 ).


            WHEN 'QCYBYENEW'.
              gr_column->set_long_text( '期初原币金额' ).
              gr_column->set_medium_text( '期初原币金额').
              gr_column->set_short_text( '期初原币金额').
              gr_column->set_output_length( 15 ).
            WHEN 'QCBBYENEW'.
              gr_column->set_long_text( '期初本币金额' ).
              gr_column->set_medium_text( '期初本币金额').
              gr_column->set_short_text( '期初本币金额').
              gr_column->set_output_length( 15 ).

            WHEN 'WSL'. "本期原币发生金额（借方）
              gr_column->set_long_text( '本期原币发生金额（借方）' ).
              gr_column->set_medium_text( '本期原币发生金额（借方）').
              gr_column->set_short_text( '本期原币金额（借方）').
              gr_column->set_output_length( 15 ).
            WHEN 'HSL'. "本期本币发生金额（借方）
              gr_column->set_long_text( '本期本币发生金额（借方）' ).
              gr_column->set_medium_text( '本期本币发生金额（借方）').
              gr_column->set_short_text( '本期本币金额（借方）').
              gr_column->set_output_length( 15 ).

            WHEN 'DRCRK'.
              gr_column->set_long_text( '期初借贷标识' ).
              gr_column->set_medium_text( '期初借贷标识').
              gr_column->set_short_text( '期初借贷标识').
              gr_column->set_output_length( 15 ).

            WHEN 'QCJDBIAOS'.
              gr_column->set_long_text( '期初借贷标识' ).
              gr_column->set_medium_text( '期初借贷标识').
              gr_column->set_short_text( '期初借贷标识').

            WHEN 'DRCRKD'.
              gr_column->set_long_text( '期末借贷标识' ).
              gr_column->set_medium_text( '期末借贷标识').
              gr_column->set_short_text( '期末借贷标识').
              gr_column->set_output_length( 15 ).


            WHEN 'DKFWSL'. "本期原币发生金额（贷方）
              gr_column->set_long_text( '本期原币发生金额（贷方）' ).
              gr_column->set_medium_text( '本期原币发生金额（贷方）').
              gr_column->set_short_text( '本期原币金额（贷方）').
              gr_column->set_output_length( 15 ).
            WHEN 'DKFHSL'. "本期本币发生金额（贷方）
              gr_column->set_long_text( '本期本币发生金额（贷方）' ).
              gr_column->set_medium_text( '本期本币发生金额（贷方）').
              gr_column->set_short_text( '本期本币金额（贷方）').
              gr_column->set_output_length( 15 ).


            WHEN 'QMYBED'. "期末原币额度
              gr_column->set_long_text( '期末原币额度' ).
              gr_column->set_medium_text( '期末原币额度').
              gr_column->set_short_text( '期末原币额度').
              gr_column->set_output_length( 15 ).
            WHEN 'QMBBED'. "期末本币额度
              gr_column->set_long_text( '期末本币额度' ).
              gr_column->set_medium_text( '期末本币额度').
              gr_column->set_short_text( '期末本币额度').
              gr_column->set_output_length( 15 ).

            WHEN 'SGTXT'. "采购订单
              gr_column->set_long_text( '文本' ).
              gr_column->set_medium_text( '文本').
              gr_column->set_short_text( '文本').
              gr_column->set_output_length( 15 ).

            WHEN 'MWSKZ'. "税码
              gr_column->set_long_text( '税码' ).
              gr_column->set_medium_text( '税码').
              gr_column->set_short_text( '税码').
              gr_column->set_output_length( 15 ).

            WHEN 'KBETR'. "税率
              gr_column->set_long_text( '税率' ).
              gr_column->set_medium_text( '税率').
              gr_column->set_short_text( '税率').
              gr_column->set_output_length( 15 ).

            WHEN 'RFAREA'. "职能范围
              gr_column->set_long_text( '职能范围' ).
              gr_column->set_medium_text( '职能范围').
              gr_column->set_short_text( '职能范围').
              gr_column->set_output_length( 15 ).

            WHEN 'FKBTX'. "职能范围的名称
              gr_column->set_long_text( '职能范围的名称' ).
              gr_column->set_medium_text( '职能范围的名称').
              gr_column->set_short_text( '职能范围的名称').
              gr_column->set_output_length( 15 ).

            WHEN OTHERS.

          ENDCASE.
        ENDLOOP.

      CATCH cx_salv_not_found INTO lo_salv_not_found.
        lv_msg = lo_salv_not_found->get_text( ).
        MESSAGE lv_msg TYPE 'E'.
    ENDTRY.

    gr_layout = gr_table->get_layout( ).
    gs_program-report = sy-repid.
    gr_layout->set_default( abap_true ).
    gr_layout->set_key( gs_program ).
    gr_layout->set_save_restriction( cl_salv_layout=>restrict_none ).


    " 2. ✅ 正确开启 SALV 标准工具栏的方法
    DATA: gr_functions TYPE REF TO cl_salv_functions_list.
    gr_functions = gr_table->get_functions( ).
    gr_functions->set_all( abap_true ).  " 这一句就能把布局按钮呼唤出来

    " 3. 显示
    gr_table->display( ).


*    gr_table->set_screen_status(
*      pfstatus      = 'STANDARD_FULLSCREEN'
*      report        = 'SAPLKKBL'
*      set_functions = gr_table->c_functions_all ).
*
*    gr_table->display( ).






  ENDMETHOD.

  METHOD write_player_detailssum.
    DATA:lt_view_input TYPE tt_view,
         ls_view_input TYPE ts_view.
    DATA:lv_dotime TYPE i.

    SELECT FROM lfa1 AS a
         FIELDS
         a~lifnr,
         concat( a~name1, concat( a~name2, a~name3 )  )  AS name
          ORDER BY lifnr
        INTO TABLE @DATA(lt_lfa1).

    SELECT FROM kna1 AS a
         FIELDS
         a~kunnr,
         concat( a~name1,  a~name2  )  AS name
          ORDER BY kunnr
        INTO TABLE @DATA(lt_kna1).


    IF me->lt_findk IS NOT INITIAL.
      APPEND LINES OF me->lt_findk TO me->lt_find.
      CLEAR:me->lt_findk.
      REFRESH me->lt_findk.

    ENDIF.

    IF me->lt_findbug IS NOT INITIAL.
      APPEND LINES OF me->lt_findbug TO me->lt_find.
      CLEAR:me->lt_findbug.
      REFRESH me->lt_findbug.
    ENDIF.

    "CHANGE
    " DELETE me->lt_find WHERE lifnr = ''.

    SORT me->lt_find BY rldnr rbukrs gjahr belnr docln racct lifnr DESCENDING.
    "CHANGE
    DELETE ADJACENT DUPLICATES FROM me->lt_find COMPARING rldnr rbukrs gjahr belnr docln racct .

* 启用cds 捞取 科目描述 begin
    SELECT * FROM zc_hkont_detail_tf( iv_ktopl = '1000',
                                      iv_saknr = '0000000000',
                                      iv_spras = '1' )
    INTO TABLE @DATA(lt_skat).
    SORT lt_skat BY ktopl saknr.
* 启用cds 捞取 科目描述 end

**   取税率 begin
    SELECT a~mwskz, "税码
           k~kbetr  "税率
      INTO TABLE @DATA(lt_konp)
      FROM a003 AS a INNER JOIN konp AS k
        ON a~knumh = k~knumh
     WHERE a~mwskz LIKE 'J%'
       AND a~aland = 'CN'.
    SORT lt_konp BY mwskz.
** 取税率 end

**    职能范围
    SELECT FROM tfkbt
      FIELDS
      spras,
      fkber,
      fkbtx
      WHERE spras = '1'
      ORDER BY spras, fkber
      INTO TABLE @DATA(lt_tfkbt).
**    职能范围



    IF s_monat-high IS NOT INITIAL.
      lv_dotime = s_monat-high - s_monat-low + 1.
    ELSE.
      lv_dotime = s_monat-low.
    ENDIF.

    DATA:lt_new_find TYPE tt_find.

    READ TABLE me->lt_poper INTO DATA(s_poper) INDEX 1.
    IF s_poper-high IS NOT INITIAL.
      DATA(lv_delpoper) = s_poper-high.
      DATA(lv_delpoplo) = s_poper-low.

      IF s_poper-high > '12'.
        lv_delpoper = '12'.
      ENDIF.
    ELSE.
      lv_delpoper = s_poper-low.
    ENDIF.

*    select FROM acdoca

    DATA:lv_zhuanh  TYPE p DECIMALS 3.
    LOOP AT me->lt_find ASSIGNING FIELD-SYMBOL(<ls_find>).
      CLEAR:lv_zhuanh.
      CALL FUNCTION 'CURRENCY_CONVERTING_FACTOR'
        EXPORTING
          currency          = <ls_find>-rwcur
        IMPORTING
          factor            = lv_zhuanh
        EXCEPTIONS
          too_many_decimals = 1
          OTHERS            = 2.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
      <ls_find>-wsl = <ls_find>-wsl * lv_zhuanh.
      <ls_find>-rldnr = ''.
      <ls_find>-docln = ''.

      IF <ls_find>-lifnr IS NOT INITIAL.
        FIND FIRST OCCURRENCE OF REGEX '[一-龥]' IN <ls_find>-lifnr.
        IF sy-subrc = 0.
          <ls_find>-delf = abap_true.
        ENDIF.
      ENDIF.


    ENDLOOP.




    TYPES: BEGIN OF ty_data,
             saknr   TYPE zfir090a-saknr,
             txt50   TYPE zfir090a-txt50,
             zfzxmlb TYPE zfir090a-zfzxmlb,
             saknr_f TYPE zfir090a-saknr,
             saknr_t TYPE zfir090a-saknr.
    TYPES: END OF ty_data.
    DATA: lt_zfir090a TYPE TABLE OF ty_data.

    SELECT *
    INTO TABLE @DATA(lt_t007s)
    FROM t007s
    WHERE spras = '1'
    AND kalsm = 'TAXCN'.


    SELECT *
    INTO CORRESPONDING FIELDS OF TABLE @lt_zfir090a
    FROM zfir090a.

    DATA:lv_num    TYPE i.
    DATA:lv_string TYPE string.
    DATA:lv_string_f TYPE string.
    DATA:lv_string_t TYPE string.
    DATA:lv_len TYPE i.
    DATA: lv_n     TYPE i .
    LOOP AT lt_zfir090a ASSIGNING FIELD-SYMBOL(<fs_zfir090a>).
      CLEAR:lv_string,lv_string_f,lv_string_t,lv_len,lv_n .
      lv_num = <fs_zfir090a>-saknr .
      lv_string =  lv_num.
      SHIFT lv_string LEFT DELETING LEADING '0'.
      CONDENSE lv_string NO-GAPS.
      lv_len =  strlen( lv_string ).
      lv_n = 10 - lv_len .
      lv_string_f  =  lv_string  && repeat( val = '0' occ = lv_n ).
      lv_string_t  =  lv_string  && repeat( val = '9' occ = lv_n ).
      <fs_zfir090a>-saknr_f = lv_string_f.
      <fs_zfir090a>-saknr_t = lv_string_t.
    ENDLOOP.



    LOOP AT lt_find ASSIGNING FIELD-SYMBOL(<fs_find>).
      LOOP AT lt_zfir090a INTO DATA(ls_zfir090a) WHERE  saknr_f <= <fs_find>-racct AND saknr_t >= <fs_find>-racct.
        <fs_find>-ddtext = ls_zfir090a-zfzxmlb.
        CONTINUE.
      ENDLOOP.

      IF <fs_find>-ddtext = 'AAC'."税
        <fs_find>-fzx = <fs_find>-mwskz.
        IF line_exists( lt_t007s[ mwskz = <fs_find>-mwskz ] ).
          <fs_find>-fzxms = lt_t007s[ mwskz = <fs_find>-mwskz ]-text1.
        ENDIF.
      ELSEIF <fs_find>-ddtext = 'AAB'."客商
        <fs_find>-fzx = <fs_find>-lifnr.
        IF line_exists( lt_lfa1[ lifnr = <fs_find>-lifnr ] ).
          <fs_find>-name1 = lt_lfa1[ lifnr = <fs_find>-lifnr ]-name.   "供应商的名字
          <fs_find>-fzxms = <fs_find>-name1.
        ELSE.
          IF line_exists( lt_kna1[ kunnr = <fs_find>-lifnr ] ).
            <fs_find>-name1 = lt_kna1[ kunnr = <fs_find>-lifnr ]-name.
            <fs_find>-fzxms = <fs_find>-name1.
          ENDIF.
        ENDIF.
      ELSEIF <fs_find>-ddtext = 'AAD'."职能范围
        <fs_find>-fzx = <fs_find>-rfarea.
        IF line_exists( lt_tfkbt[ fkber  =  <fs_find>-rfarea ] ).
          <fs_find>-fzxms =  lt_tfkbt[ fkber  =  <fs_find>-rfarea ]-fkbtx.
        ENDIF.
      ENDIF.
    ENDLOOP.




    DELETE me->lt_find WHERE delf = abap_true.
    " DELETE me->lt_find WHERE lifnr = ''.
    APPEND LINES OF me->lt_find TO lt_new_find.
    DELETE lt_new_find WHERE gjahr <> p_gjahr.
    DELETE lt_new_find WHERE poper > lv_delpoper.
    DELETE lt_new_find WHERE poper < lv_delpoplo.
    DELETE lt_new_find WHERE racct NOT IN s_racct.  "增加这个科目排除


    SELECT FROM @lt_new_find AS a                           "mod-0001
    INNER JOIN  bseg AS b  ##ITAB_KEY_IN_SELECT
         ON  a~rbukrs = b~bukrs
         AND a~gjahr  = b~gjahr
         AND a~belnr  = b~belnr
         " 核心改动：使用 CAST 将 LPAD 的结果强制转换为 CHAR 6，与 DOCLN 完美握手
         AND a~buzei  = b~buzei
       FIELDS
         b~bukrs,
         b~belnr,
         b~gjahr,
         " SELECT 投影列里也同样使用 CAST 保证输出类型的严谨
         b~buzei,
         b~xnegp,
         b~shkzg
       INTO TABLE @DATA(lt_bsegnew).

    IF sy-subrc = 0.
      SORT lt_bsegnew BY bukrs belnr gjahr buzei.
    ENDIF.


    DATA:lv_datum TYPE sy-datum.

**    直接算期初 数据
    lv_datum = p_gjahr && s_monat-low && |01|.
    lv_datum = lv_datum - 1.


    SELECT FROM @me->lt_find AS a ##ITAB_KEY_IN_SELECT ##ITAB_DB_SELECT
      FIELDS
      a~rbukrs,
     " a~lifnr,
      a~racct,
      a~ddtext,
      a~fzx,
       a~fzxms,
      a~rwcur,
      a~rhcur
      WHERE a~gjahr <= @p_gjahr
   "   GROUP BY a~rbukrs, a~lifnr, a~racct, a~rwcur, a~rhcur
      GROUP BY a~rbukrs,  a~racct,a~ddtext,a~fzx, a~fzxms, a~rwcur, a~rhcur
     ORDER BY a~rbukrs,  a~racct,a~ddtext,a~fzx, a~fzxms, a~rwcur, a~rhcur
      INTO TABLE @DATA(lt_order).

    LOOP AT lt_order INTO DATA(ls_order).
      ls_view_input-budat  = lv_datum.
      ls_view_input-gjahr  = p_gjahr.
      "  ls_view_input-lifnr  = ls_order-lifnr.
      ls_view_input-poper  = s_monat-low.
      ls_view_input-racct  = ls_order-racct.
      ls_view_input-ddtext  = ls_order-ddtext.
      ls_view_input-fzx  = ls_order-fzx.
      ls_view_input-fzxms  = ls_order-fzxms.
      ls_view_input-rbukrs = ls_order-rbukrs.
      ls_view_input-rwcur  = ls_order-rwcur. "原币
      ls_view_input-rhcur  = ls_order-rhcur. "人民币
      COLLECT ls_view_input INTO lt_view_input.
      CLEAR:ls_view_input.
    ENDLOOP.

    IF s_waers-low = '*' . "如果选择屏幕不是人民币
    ELSE.
      IF c_zhbwb = ''.
        DELETE lt_view_input WHERE rwcur <> s_waers-low.
      ENDIF.
    ENDIF.

    DATA:lt_parallel_sum TYPE tt_find.
    DATA:ls_find_col TYPE ts_s_find.
    LOOP AT lt_view_input INTO ls_view_input.
      LOOP AT lt_find ASSIGNING <ls_find> WHERE  rbukrs = ls_view_input-rbukrs
                                         "   AND  lifnr  = ls_view_input-lifnr
                                            AND  racct  = ls_view_input-racct
                                            AND  ddtext  = ls_view_input-ddtext
                                            AND  fzx  = ls_view_input-fzx
                                            AND  fzxms  = ls_view_input-fzxms
                                            AND  budat  <= ls_view_input-budat
                                            AND  rwcur  = ls_view_input-rwcur
                                            AND  rhcur  = ls_view_input-rhcur.
        ls_find_col-rbukrs = <ls_find>-rbukrs.
        " ls_find_col-lifnr = <ls_find>-lifnr.
        ls_find_col-poper = ls_view_input-poper.
        ls_find_col-racct = <ls_find>-racct.
        ls_find_col-ddtext = <ls_find>-ddtext.
        ls_find_col-fzx = <ls_find>-fzx.
        ls_find_col-fzxms = <ls_find>-fzxms.
        ls_find_col-rwcur = <ls_find>-rwcur.
        ls_find_col-rhcur = <ls_find>-rhcur.
        ls_find_col-wsl   = <ls_find>-wsl.


        ls_find_col-hsl   = <ls_find>-hsl.
        COLLECT ls_find_col INTO lt_parallel_sum.
        CLEAR:ls_find_col.                                                     .
      ENDLOOP.

    ENDLOOP.


    CLEAR:lt_find.
    REFRESH:lt_find.



    SORT lt_parallel_sum BY rbukrs lifnr gjahr poper racct rwcur rhcur . "这个不变

    SORT lt_new_find BY rbukrs lifnr gjahr poper racct budat.
    CLEAR: me->lt_alv_sum.

    LOOP AT lt_view_input INTO ls_view_input.

      APPEND INITIAL LINE TO me->lt_alv_sum ASSIGNING FIELD-SYMBOL(<ls_alv_sum>).
      <ls_alv_sum>-rbukrs = ls_view_input-rbukrs. "公司代码
      "   <ls_alv_sum>-lifnr  = ls_view_input-lifnr.   "供应商


      <ls_alv_sum>-racct  = ls_view_input-racct.
      <ls_alv_sum>-ddtext  = ls_view_input-ddtext.
      <ls_alv_sum>-fzx  = ls_view_input-fzx.
      <ls_alv_sum>-fzxms  = ls_view_input-fzxms.


      READ TABLE lt_skat INTO DATA(ls_skat) WITH KEY saknr = <ls_alv_sum>-racct
                                           BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_alv_sum>-txt50 = ls_skat-txt50.
      ENDIF.


      <ls_alv_sum>-rwcur = ls_view_input-rwcur.
      <ls_alv_sum>-rhcur = ls_view_input-rhcur.

      READ TABLE lt_parallel_sum INTO DATA(ls_parallel_sum) WITH KEY  rbukrs = ls_view_input-rbukrs
                                                          "  lifnr  = ls_view_input-lifnr
                                                            racct  = ls_view_input-racct
                                                            ddtext  = ls_view_input-ddtext
                                                            fzx  = ls_view_input-fzx
                                                            fzxms  = ls_view_input-fzxms
                                                            rwcur  = ls_view_input-rwcur
                                                            rhcur  = ls_view_input-rhcur.
      IF sy-subrc = 0.
        IF ls_parallel_sum-hsl > 0.
          <ls_alv_sum>-qcybed = ls_parallel_sum-wsl.   " 期初原币额度
          <ls_alv_sum>-qcbbed = ls_parallel_sum-hsl."期初本币额度
          <ls_alv_sum>-drcrk = '借'.
        ELSEIF ls_parallel_sum-hsl < 0..
          <ls_alv_sum>-qcdfybed = ls_parallel_sum-wsl."期初贷方原币额度
          <ls_alv_sum>-qcdfbbed = ls_parallel_sum-hsl."期初贷方本币额度
          <ls_alv_sum>-drdfcrk = '贷'.
        ELSEIF ls_parallel_sum-hsl = 0..
          <ls_alv_sum>-qcdfybed = ls_parallel_sum-wsl."期初贷方原币额度
          <ls_alv_sum>-qcdfbbed = ls_parallel_sum-hsl."期初贷方本币额度
          <ls_alv_sum>-drdfcrk = '平'.
        ENDIF.

        IF <ls_alv_sum>-drcrk IS INITIAL.
          <ls_alv_sum>-drcrk = '平'.
        ENDIF.

*      期初原币余额 = 期初原币额度   借方期初               +   期初原币额度   贷方期初
        <ls_alv_sum>-qcybyenew  = <ls_alv_sum>-qcybed + <ls_alv_sum>-qcdfybed.

*      期初本币余额 = 期初本币额度   借方期初               +   期初本币额度   贷方期初
        <ls_alv_sum>-qcbbyenew  =  <ls_alv_sum>-qcbbed + <ls_alv_sum>-qcdfbbed.

        IF <ls_alv_sum>-qcbbyenew > 0.       "期初借贷标识
          <ls_alv_sum>-qcjdbiaos = '借'.
        ELSEIF <ls_alv_sum>-qcbbyenew < 0..
          <ls_alv_sum>-qcjdbiaos = '贷'.
        ELSE.
          <ls_alv_sum>-qcjdbiaos = '平'.
        ENDIF.

      ENDIF.


      DATA:lv_wsl_s TYPE acdoca-wsl,
           lv_hsl_s TYPE acdoca-hsl,
           lv_wsl_h TYPE acdoca-wsl,
           lv_hsl_h TYPE acdoca-hsl.

      CLEAR:
        lv_wsl_s,
        lv_hsl_s,
        lv_wsl_h,
        lv_hsl_h.

      LOOP AT lt_new_find INTO DATA(ls_new_find) WHERE  rbukrs = ls_view_input-rbukrs
                                                 "   AND  lifnr  = ls_view_input-lifnr
                                                    AND  racct  = ls_view_input-racct
                                                    AND  ddtext  = ls_view_input-ddtext
                                                    AND  fzx  = ls_view_input-fzx
                                                    AND  fzxms  = ls_view_input-fzxms
                                                    AND  rwcur  = ls_view_input-rwcur
                                                    AND  rhcur  = ls_view_input-rhcur.
*        IF ls_new_find-wsl >= 0.
*          lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
*        ELSE.
*          lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
*        ENDIF.
*
*        IF ls_new_find-hsl >= 0.
*          lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
*        ELSE.
*          lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
*        ENDIF.
        READ TABLE lt_bsegnew INTO DATA(ls_bsegnew) WITH KEY "mod-0001
       bukrs = ls_new_find-rbukrs
       gjahr = ls_new_find-gjahr
       belnr = ls_new_find-belnr
       buzei = ls_new_find-buzei
       BINARY SEARCH.
        IF sy-subrc = 0 .
          IF ls_bsegnew-xnegp = 'X'.
            IF ls_bsegnew-shkzg = 'S'.
              lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
              lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
            ELSEIF ls_bsegnew-shkzg = 'H'.
              lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
              lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
            ENDIF.
          ELSE.
            IF ls_new_find-wsl >= 0.
              lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
            ELSE.
              lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
            ENDIF.

            IF ls_new_find-hsl >= 0.
              lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
            ELSE.
              lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
            ENDIF.
          ENDIF.
        ELSE.
          IF ls_new_find-wsl >= 0.
            lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
          ELSE.
            lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
          ENDIF.

          IF ls_new_find-hsl >= 0.
            lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
          ELSE.
            lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
          ENDIF.

        ENDIF.
        CLEAR:ls_bsegnew.

      ENDLOOP.

      <ls_alv_sum>-wsl    = lv_wsl_s.
      <ls_alv_sum>-dkfwsl = lv_wsl_h.

      <ls_alv_sum>-hsl    = lv_hsl_s.
      <ls_alv_sum>-dkfhsl = lv_hsl_h.

      <ls_alv_sum>-qmybed = <ls_alv_sum>-qcybed +  <ls_alv_sum>-qcdfybed
                                  + <ls_alv_sum>-wsl + <ls_alv_sum>-dkfwsl.

      <ls_alv_sum>-qmbbed = <ls_alv_sum>-qcbbed + <ls_alv_sum>-qcdfbbed
                                    + <ls_alv_sum>-hsl  + <ls_alv_sum>-dkfhsl.


      IF <ls_alv_sum>-qmybed > 0.
        <ls_alv_sum>-drcrkd = '借'.
      ELSEIF <ls_alv_sum>-qmybed < 0..
        <ls_alv_sum>-drcrkd = '贷'.
      ELSEIF <ls_alv_sum>-qmybed = 0..
        <ls_alv_sum>-drcrkd = '平'.
      ENDIF.

    ENDLOOP.


    LOOP AT lt_alv_sum ASSIGNING FIELD-SYMBOL(<fs_alv_sum>).

      IF <fs_alv_sum>-ddtext = 'AAA'.
        <fs_alv_sum>-fzxlbms = '银行'.
      ELSEIF <fs_alv_sum>-ddtext = 'AAB'.
        <fs_alv_sum>-fzxlbms = '客商'.
      ELSEIF <fs_alv_sum>-ddtext = 'AAC'.
        <fs_alv_sum>-fzxlbms = '税率'.
      ELSEIF <fs_alv_sum>-ddtext = 'AAD'.
        <fs_alv_sum>-fzxlbms = '职能范围'.
      ENDIF.

      IF <fs_alv_sum>-qcbbyenew > '0'.
        <fs_alv_sum>-qcjdbiaos = '借'.
      ELSEIF <fs_alv_sum>-qcbbyenew < '0'..
        <fs_alv_sum>-qcjdbiaos = '贷'.
      ELSE.
        <fs_alv_sum>-qcjdbiaos = '平'.
      ENDIF.

      IF <fs_alv_sum>-qmbbed > '0'.
        <fs_alv_sum>-drcrkd = '借'.
      ELSEIF <fs_alv_sum>-qmbbed < '0'. .
        <fs_alv_sum>-drcrkd = '贷'.
      ELSEIF <fs_alv_sum>-qmbbed = '0'. .
        <fs_alv_sum>-drcrkd = '平'.
      ENDIF.

    ENDLOOP.



  ENDMETHOD.


  METHOD write_player_detailssum2.
    DATA:lt_view_input TYPE tt_view,
         ls_view_input TYPE ts_view.
    DATA:lv_dotime TYPE i.

    SELECT FROM lfa1 AS a
         FIELDS
         a~lifnr,
         concat( a~name1, concat( a~name2, a~name3 )  )  AS name
          ORDER BY lifnr
        INTO TABLE @DATA(lt_lfa1).

    SELECT FROM kna1 AS a
         FIELDS
         a~kunnr,
         concat( a~name1,  a~name2  )  AS name
          ORDER BY kunnr
        INTO TABLE @DATA(lt_kna1).


    IF me->lt_findk IS NOT INITIAL.
      APPEND LINES OF me->lt_findk TO me->lt_find.
      CLEAR:me->lt_findk.
      REFRESH me->lt_findk.

    ENDIF.

    IF me->lt_findbug IS NOT INITIAL.
      APPEND LINES OF me->lt_findbug TO me->lt_find.
      CLEAR:me->lt_findbug.
      REFRESH me->lt_findbug.
    ENDIF.

    "CHANGE
    " DELETE me->lt_find WHERE lifnr = ''.

    SORT me->lt_find BY rldnr rbukrs gjahr belnr docln racct lifnr DESCENDING.
    "CHANGE
    DELETE ADJACENT DUPLICATES FROM me->lt_find COMPARING rldnr rbukrs gjahr belnr docln racct .

* 启用cds 捞取 科目描述 begin
    SELECT * FROM zc_hkont_detail_tf( iv_ktopl = '1000',
                                      iv_saknr = '0000000000',
                                      iv_spras = '1' )
    INTO TABLE @DATA(lt_skat).
    SORT lt_skat BY ktopl saknr.
* 启用cds 捞取 科目描述 end

**   取税率 begin
    SELECT a~mwskz, "税码
           k~kbetr  "税率
      INTO TABLE @DATA(lt_konp)
      FROM a003 AS a INNER JOIN konp AS k
        ON a~knumh = k~knumh
     WHERE a~mwskz LIKE 'J%'
       AND a~aland = 'CN'.
    SORT lt_konp BY mwskz.
** 取税率 end

**    职能范围
    SELECT FROM tfkbt
      FIELDS
      spras,
      fkber,
      fkbtx
      WHERE spras = '1'
      ORDER BY spras, fkber
      INTO TABLE @DATA(lt_tfkbt).
**    职能范围



    IF s_monat-high IS NOT INITIAL.
      lv_dotime = s_monat-high - s_monat-low + 1.
    ELSE.
      lv_dotime = s_monat-low.
    ENDIF.

    DATA:lt_new_find TYPE tt_find.

    READ TABLE me->lt_poper INTO DATA(s_poper) INDEX 1.
    IF s_poper-high IS NOT INITIAL.
      DATA(lv_delpoper) = s_poper-high.
      DATA(lv_delpoplo) = s_poper-low.

      IF s_poper-high > '12'.
        lv_delpoper = '12'.
      ENDIF.
    ELSE.
      lv_delpoper = s_poper-low.
    ENDIF.

*    select FROM acdoca

    DATA:lv_zhuanh  TYPE p DECIMALS 3.
    LOOP AT me->lt_find ASSIGNING FIELD-SYMBOL(<ls_find>).
      CLEAR:lv_zhuanh.
      CALL FUNCTION 'CURRENCY_CONVERTING_FACTOR'
        EXPORTING
          currency          = <ls_find>-rwcur
        IMPORTING
          factor            = lv_zhuanh
        EXCEPTIONS
          too_many_decimals = 1
          OTHERS            = 2.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
      <ls_find>-wsl = <ls_find>-wsl * lv_zhuanh.
      <ls_find>-rldnr = ''.
      <ls_find>-docln = ''.

      IF <ls_find>-lifnr IS NOT INITIAL.
        FIND FIRST OCCURRENCE OF REGEX '[一-龥]' IN <ls_find>-lifnr.
        IF sy-subrc = 0.
          <ls_find>-delf = abap_true.
        ENDIF.
      ENDIF.


    ENDLOOP.




    TYPES: BEGIN OF ty_data,
             saknr   TYPE zfir090a-saknr,
             txt50   TYPE zfir090a-txt50,
             zfzxmlb TYPE zfir090a-zfzxmlb,
             saknr_f TYPE zfir090a-saknr,
             saknr_t TYPE zfir090a-saknr.
    TYPES: END OF ty_data.
    DATA: lt_zfir090a TYPE TABLE OF ty_data.

    SELECT *
    INTO TABLE @DATA(lt_t007s)
    FROM t007s
    WHERE spras = '1'
    AND kalsm = 'TAXCN'.


*    SELECT *
*    INTO CORRESPONDING FIELDS OF TABLE @lt_zfir090a
*    FROM zfir090a.

*    DATA:lv_num    TYPE i.
*    DATA:lv_string TYPE string.
*    DATA:lv_string_f TYPE string.
*    DATA:lv_string_t TYPE string.
*    DATA:lv_len TYPE i.
*    DATA: lv_n     TYPE i .
*    LOOP AT lt_zfir090a ASSIGNING FIELD-SYMBOL(<fs_zfir090a>).
*      CLEAR:lv_string,lv_string_f,lv_string_t,lv_len,lv_n .
*      lv_num = <fs_zfir090a>-saknr .
*      lv_string =  lv_num.
*      SHIFT lv_string LEFT DELETING LEADING '0'.
*      CONDENSE lv_string NO-GAPS.
*      lv_len =  strlen( lv_string ).
*      lv_n = 10 - lv_len .
*      lv_string_f  =  lv_string  && repeat( val = '0' occ = lv_n ).
*      lv_string_t  =  lv_string  && repeat( val = '9' occ = lv_n ).
*      <fs_zfir090a>-saknr_f = lv_string_f.
*      <fs_zfir090a>-saknr_t = lv_string_t.
*    ENDLOOP.



*    LOOP AT lt_find ASSIGNING FIELD-SYMBOL(<fs_find>).
*      LOOP AT lt_zfir090a INTO DATA(ls_zfir090a) WHERE  saknr_f <= <fs_find>-racct AND saknr_t >= <fs_find>-racct.
*        <fs_find>-ddtext = ls_zfir090a-zfzxmlb.
*        CONTINUE.
*      ENDLOOP.
*
*      IF <fs_find>-ddtext = 'AAC'."税
*        <fs_find>-fzx = <fs_find>-mwskz.
*        IF line_exists( lt_t007s[ mwskz = <fs_find>-mwskz ] ).
*          <fs_find>-fzxms = lt_t007s[ mwskz = <fs_find>-mwskz ]-text1.
*        ENDIF.
*      ELSEIF <fs_find>-ddtext = 'AAB'."客商
*        <fs_find>-fzx = <fs_find>-lifnr.
*        IF line_exists( lt_lfa1[ lifnr = <fs_find>-lifnr ] ).
*          <fs_find>-name1 = lt_lfa1[ lifnr = <fs_find>-lifnr ]-name.   "供应商的名字
*          <fs_find>-fzxms = <fs_find>-name1.
*        ELSE.
*          IF line_exists( lt_kna1[ kunnr = <fs_find>-lifnr ] ).
*            <fs_find>-name1 = lt_kna1[ kunnr = <fs_find>-lifnr ]-name.
*            <fs_find>-fzxms = <fs_find>-name1.
*          ENDIF.
*        ENDIF.
*      ELSEIF <fs_find>-ddtext = 'AAD'."职能范围
*        <fs_find>-fzx = <fs_find>-rfarea.
*        IF line_exists( lt_tfkbt[ fkber  =  <fs_find>-rfarea ] ).
*          <fs_find>-fzxms =  lt_tfkbt[ fkber  =  <fs_find>-rfarea ]-fkbtx.
*        ENDIF.
*      ENDIF.
*    ENDLOOP.




    DELETE me->lt_find WHERE delf = abap_true.
    " DELETE me->lt_find WHERE lifnr = ''.
    APPEND LINES OF me->lt_find TO lt_new_find.
    DELETE lt_new_find WHERE gjahr <> p_gjahr.
    DELETE lt_new_find WHERE poper > lv_delpoper.
    DELETE lt_new_find WHERE poper < lv_delpoplo.
    DELETE lt_new_find WHERE racct NOT IN s_racct.  "增加这个科目排除

    SELECT FROM @lt_new_find AS a                           "mod-0001
       INNER JOIN  bseg AS b  ##ITAB_KEY_IN_SELECT
            ON  a~rbukrs = b~bukrs
            AND a~gjahr  = b~gjahr
            AND a~belnr  = b~belnr
            " 核心改动：使用 CAST 将 LPAD 的结果强制转换为 CHAR 6，与 DOCLN 完美握手
            AND a~buzei  = b~buzei
          FIELDS
            b~bukrs,
            b~belnr,
            b~gjahr,
            " SELECT 投影列里也同样使用 CAST 保证输出类型的严谨
            b~buzei,
            b~xnegp,
            b~shkzg
          INTO TABLE @DATA(lt_bsegnew).
    DATA:lv_datum TYPE sy-datum.

**    直接算期初 数据
    lv_datum = p_gjahr && s_monat-low && |01|.
    lv_datum = lv_datum - 1.


    SELECT FROM @me->lt_find AS a ##ITAB_KEY_IN_SELECT ##ITAB_DB_SELECT
      FIELDS
      a~rbukrs,
     " a~lifnr,
      a~racct,
*      a~ddtext,
*      a~fzx,
*       a~fzxms,
      a~rwcur,
      a~rhcur
      WHERE a~gjahr <= @p_gjahr
*      GROUP BY a~rbukrs,  a~racct,a~ddtext,a~fzx, a~fzxms, a~rwcur, a~rhcur
*     ORDER BY a~rbukrs,  a~racct,a~ddtext,a~fzx, a~fzxms, a~rwcur, a~rhcur
      GROUP BY a~rbukrs,  a~racct, a~rwcur, a~rhcur
      ORDER BY a~rbukrs,  a~racct, a~rwcur, a~rhcur
      INTO TABLE @DATA(lt_order).

    LOOP AT lt_order INTO DATA(ls_order).
      ls_view_input-budat  = lv_datum.
      ls_view_input-gjahr  = p_gjahr.
      ls_view_input-poper  = s_monat-low.
      ls_view_input-racct  = ls_order-racct.
*      ls_view_input-ddtext  = ls_order-ddtext.
*      ls_view_input-fzx  = ls_order-fzx.
*      ls_view_input-fzxms  = ls_order-fzxms.
      ls_view_input-rbukrs = ls_order-rbukrs.
      ls_view_input-rwcur  = ls_order-rwcur. "原币
      ls_view_input-rhcur  = ls_order-rhcur. "人民币
      COLLECT ls_view_input INTO lt_view_input.
      CLEAR:ls_view_input.
    ENDLOOP.

    IF s_waers-low = '*' . "如果选择屏幕不是人民币
    ELSE.
      IF c_zhbwb = ''.
        DELETE lt_view_input WHERE rwcur <> s_waers-low.
      ENDIF.
    ENDIF.

    DATA:lt_parallel_sum TYPE tt_find.
    DATA:ls_find_col TYPE ts_s_find.
    LOOP AT lt_view_input INTO ls_view_input.
      LOOP AT lt_find ASSIGNING <ls_find> WHERE  rbukrs = ls_view_input-rbukrs
                                         "   AND  lifnr  = ls_view_input-lifnr
                                            AND  racct  = ls_view_input-racct
*                                            AND  ddtext  = ls_view_input-ddtext
*                                            AND  fzx  = ls_view_input-fzx
*                                            AND  fzxms  = ls_view_input-fzxms
                                            AND  budat  <= ls_view_input-budat
                                            AND  rwcur  = ls_view_input-rwcur
                                            AND  rhcur  = ls_view_input-rhcur.
        ls_find_col-rbukrs = <ls_find>-rbukrs.
        " ls_find_col-lifnr = <ls_find>-lifnr.
        ls_find_col-poper = ls_view_input-poper.
        ls_find_col-racct = <ls_find>-racct.
*        ls_find_col-ddtext = <ls_find>-ddtext.
*        ls_find_col-fzx = <ls_find>-fzx.
*        ls_find_col-fzxms = <ls_find>-fzxms.
        ls_find_col-rwcur = <ls_find>-rwcur.
        ls_find_col-rhcur = <ls_find>-rhcur.
        ls_find_col-wsl   = <ls_find>-wsl.


        ls_find_col-hsl   = <ls_find>-hsl.
        COLLECT ls_find_col INTO lt_parallel_sum.
        CLEAR:ls_find_col.                                                     .
      ENDLOOP.

    ENDLOOP.


    CLEAR:lt_find.
    REFRESH:lt_find.



    SORT lt_parallel_sum BY rbukrs lifnr gjahr poper racct rwcur rhcur . "这个不变

    SORT lt_new_find BY rbukrs lifnr gjahr poper racct budat.
    CLEAR: me->lt_alv_sum.

    LOOP AT lt_view_input INTO ls_view_input.

      APPEND INITIAL LINE TO me->lt_alv_sum ASSIGNING FIELD-SYMBOL(<ls_alv_sum>).
      <ls_alv_sum>-rbukrs = ls_view_input-rbukrs. "公司代码
      "   <ls_alv_sum>-lifnr  = ls_view_input-lifnr.   "供应商
      <ls_alv_sum>-racct  = ls_view_input-racct.
*      <ls_alv_sum>-ddtext  = ls_view_input-ddtext.
*      <ls_alv_sum>-fzx  = ls_view_input-fzx.
*      <ls_alv_sum>-fzxms  = ls_view_input-fzxms.


      READ TABLE lt_skat INTO DATA(ls_skat) WITH KEY saknr = <ls_alv_sum>-racct
                                           BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_alv_sum>-txt50 = ls_skat-txt50.
      ENDIF.


      <ls_alv_sum>-rwcur = ls_view_input-rwcur.
      <ls_alv_sum>-rhcur = ls_view_input-rhcur.

      READ TABLE lt_parallel_sum INTO DATA(ls_parallel_sum) WITH KEY  rbukrs = ls_view_input-rbukrs
                                                          "  lifnr  = ls_view_input-lifnr
                                                            racct  = ls_view_input-racct
*                                                            ddtext  = ls_view_input-ddtext
*                                                            fzx  = ls_view_input-fzx
*                                                            fzxms  = ls_view_input-fzxms
                                                            rwcur  = ls_view_input-rwcur
                                                            rhcur  = ls_view_input-rhcur.
      IF sy-subrc = 0.
        IF ls_parallel_sum-hsl > 0.
          <ls_alv_sum>-qcybed = ls_parallel_sum-wsl.   " 期初原币额度
          <ls_alv_sum>-qcbbed = ls_parallel_sum-hsl."期初本币额度
          <ls_alv_sum>-drcrk = '借'.
        ELSEIF ls_parallel_sum-hsl < 0..
          <ls_alv_sum>-qcdfybed = ls_parallel_sum-wsl."期初贷方原币额度
          <ls_alv_sum>-qcdfbbed = ls_parallel_sum-hsl."期初贷方本币额度
          <ls_alv_sum>-drdfcrk = '贷'.
        ELSEIF ls_parallel_sum-hsl = 0..
          <ls_alv_sum>-qcdfybed = ls_parallel_sum-wsl."期初贷方原币额度
          <ls_alv_sum>-qcdfbbed = ls_parallel_sum-hsl."期初贷方本币额度
          <ls_alv_sum>-drdfcrk = '平'.
        ENDIF.

        IF <ls_alv_sum>-drcrk IS INITIAL.
          <ls_alv_sum>-drcrk = '平'.
        ENDIF.

*      期初原币余额 = 期初原币额度   借方期初               +   期初原币额度   贷方期初
        <ls_alv_sum>-qcybyenew  = <ls_alv_sum>-qcybed + <ls_alv_sum>-qcdfybed.

*      期初本币余额 = 期初本币额度   借方期初               +   期初本币额度   贷方期初
        <ls_alv_sum>-qcbbyenew  =  <ls_alv_sum>-qcbbed + <ls_alv_sum>-qcdfbbed.

        IF <ls_alv_sum>-qcbbyenew > 0.       "期初借贷标识
          <ls_alv_sum>-qcjdbiaos = '借'.
        ELSEIF <ls_alv_sum>-qcbbyenew < 0..
          <ls_alv_sum>-qcjdbiaos = '贷'.
        ELSE.
          <ls_alv_sum>-qcjdbiaos = '平'.
        ENDIF.

      ENDIF.


      DATA:lv_wsl_s TYPE acdoca-wsl,
           lv_hsl_s TYPE acdoca-hsl,
           lv_wsl_h TYPE acdoca-wsl,
           lv_hsl_h TYPE acdoca-hsl.

      CLEAR:
        lv_wsl_s,
        lv_hsl_s,
        lv_wsl_h,
        lv_hsl_h.

      LOOP AT lt_new_find INTO DATA(ls_new_find) WHERE  rbukrs = ls_view_input-rbukrs
                                                 "   AND  lifnr  = ls_view_input-lifnr
                                                    AND  racct  = ls_view_input-racct
*                                                    AND  ddtext  = ls_view_input-ddtext
*                                                    AND  fzx  = ls_view_input-fzx
*                                                    AND  fzxms  = ls_view_input-fzxms
                                                    AND  rwcur  = ls_view_input-rwcur
                                                    AND  rhcur  = ls_view_input-rhcur.
*        IF ls_new_find-wsl >= 0.
*          lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
*        ELSE.
*          lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
*        ENDIF.
*
*        IF ls_new_find-hsl >= 0.
*          lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
*        ELSE.
*          lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
*        ENDIF.
        READ TABLE lt_bsegnew INTO DATA(ls_bsegnew) WITH KEY "mod-0001
     bukrs = ls_new_find-rbukrs
     gjahr = ls_new_find-gjahr
     belnr = ls_new_find-belnr
     buzei = ls_new_find-buzei
     BINARY SEARCH.
        IF sy-subrc = 0 .
          IF ls_bsegnew-xnegp = 'X'.
            IF ls_bsegnew-shkzg = 'S'.
              lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
              lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
            ELSEIF ls_bsegnew-shkzg = 'H'.
              lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
              lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
            ENDIF.
          ELSE.
            IF ls_new_find-wsl >= 0.
              lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
            ELSE.
              lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
            ENDIF.

            IF ls_new_find-hsl >= 0.
              lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
            ELSE.
              lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
            ENDIF.
          ENDIF.
        ELSE.
          IF ls_new_find-wsl >= 0.
            lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
          ELSE.
            lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
          ENDIF.

          IF ls_new_find-hsl >= 0.
            lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
          ELSE.
            lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
          ENDIF.

        ENDIF.
        CLEAR:ls_bsegnew.

      ENDLOOP.

      <ls_alv_sum>-wsl    = lv_wsl_s.
      <ls_alv_sum>-dkfwsl = lv_wsl_h.

      <ls_alv_sum>-hsl    = lv_hsl_s.
      <ls_alv_sum>-dkfhsl = lv_hsl_h.

      <ls_alv_sum>-qmybed = <ls_alv_sum>-qcybed +  <ls_alv_sum>-qcdfybed
                                  + <ls_alv_sum>-wsl + <ls_alv_sum>-dkfwsl.

      <ls_alv_sum>-qmbbed = <ls_alv_sum>-qcbbed + <ls_alv_sum>-qcdfbbed
                                    + <ls_alv_sum>-hsl  + <ls_alv_sum>-dkfhsl.


      IF <ls_alv_sum>-qmybed > 0.
        <ls_alv_sum>-drcrkd = '借'.
      ELSEIF <ls_alv_sum>-qmybed < 0..
        <ls_alv_sum>-drcrkd = '贷'.
      ELSEIF <ls_alv_sum>-qmybed = 0..
        <ls_alv_sum>-drcrkd = '平'.
      ENDIF.

    ENDLOOP.


    LOOP AT lt_alv_sum ASSIGNING FIELD-SYMBOL(<fs_alv_sum>).


      IF <fs_alv_sum>-qcbbyenew > '0'.
        <fs_alv_sum>-qcjdbiaos = '借'.
      ELSEIF <fs_alv_sum>-qcbbyenew < '0'..
        <fs_alv_sum>-qcjdbiaos = '贷'.
      ELSE.
        <fs_alv_sum>-qcjdbiaos = '平'.
      ENDIF.

      IF <fs_alv_sum>-qmbbed > '0'.
        <fs_alv_sum>-drcrkd = '借'.
      ELSEIF <fs_alv_sum>-qmbbed < '0'. .
        <fs_alv_sum>-drcrkd = '贷'.
      ELSEIF <fs_alv_sum>-qmbbed = '0'. .
        <fs_alv_sum>-drcrkd = '平'.
      ENDIF.

    ENDLOOP.



  ENDMETHOD.


  METHOD write_player_detailssum3.
    DATA:lt_view_input TYPE tt_view,
         ls_view_input TYPE ts_view.
    DATA:lv_dotime TYPE i.

    SELECT FROM lfa1 AS a
         FIELDS
         a~lifnr,
         concat( a~name1, concat( a~name2, a~name3 )  )  AS name
          ORDER BY lifnr
        INTO TABLE @DATA(lt_lfa1).

    SELECT FROM kna1 AS a
         FIELDS
         a~kunnr,
         concat( a~name1,  a~name2  )  AS name
          ORDER BY kunnr
        INTO TABLE @DATA(lt_kna1).


    IF me->lt_findk IS NOT INITIAL.
      APPEND LINES OF me->lt_findk TO me->lt_find.
      CLEAR:me->lt_findk.
      REFRESH me->lt_findk.

    ENDIF.

    IF me->lt_findbug IS NOT INITIAL.
      APPEND LINES OF me->lt_findbug TO me->lt_find.
      CLEAR:me->lt_findbug.
      REFRESH me->lt_findbug.
    ENDIF.





    "CHANGE
    " DELETE me->lt_find WHERE lifnr = ''.

    SORT me->lt_find BY rldnr rbukrs gjahr belnr docln racct lifnr DESCENDING.
    "CHANGE
    DELETE ADJACENT DUPLICATES FROM me->lt_find COMPARING rldnr rbukrs gjahr belnr docln racct .

* 启用cds 捞取 科目描述 begin
    SELECT * FROM zc_hkont_detail_tf( iv_ktopl = '1000',
                                      iv_saknr = '0000000000',
                                      iv_spras = '1' )
    INTO TABLE @DATA(lt_skat).
    SORT lt_skat BY ktopl saknr.
* 启用cds 捞取 科目描述 end

**   取税率 begin
    SELECT a~mwskz, "税码
           k~kbetr  "税率
      INTO TABLE @DATA(lt_konp)
      FROM a003 AS a INNER JOIN konp AS k
        ON a~knumh = k~knumh
     WHERE a~mwskz LIKE 'J%'
       AND a~aland = 'CN'.
    SORT lt_konp BY mwskz.
** 取税率 end

**    职能范围
    SELECT FROM tfkbt
      FIELDS
      spras,
      fkber,
      fkbtx
      WHERE spras = '1'
      ORDER BY spras, fkber
      INTO TABLE @DATA(lt_tfkbt).
**    职能范围



    IF s_monat-high IS NOT INITIAL.
      lv_dotime = s_monat-high - s_monat-low + 1.
    ELSE.
      lv_dotime = s_monat-low.
    ENDIF.

    DATA:lt_new_find TYPE tt_find.

    READ TABLE me->lt_poper INTO DATA(s_poper) INDEX 1.
    IF s_poper-high IS NOT INITIAL.
      DATA(lv_delpoper) = s_poper-high.
      DATA(lv_delpoplo) = s_poper-low.

      IF s_poper-high > '12'.
        lv_delpoper = '12'.
      ENDIF.
    ELSE.
      lv_delpoper = s_poper-low.
    ENDIF.

*    select FROM acdoca

    DATA:lv_zhuanh  TYPE p DECIMALS 3.
    LOOP AT me->lt_find ASSIGNING FIELD-SYMBOL(<ls_find>).
      CLEAR:lv_zhuanh.
      CALL FUNCTION 'CURRENCY_CONVERTING_FACTOR'
        EXPORTING
          currency          = <ls_find>-rwcur
        IMPORTING
          factor            = lv_zhuanh
        EXCEPTIONS
          too_many_decimals = 1
          OTHERS            = 2.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
      <ls_find>-wsl = <ls_find>-wsl * lv_zhuanh.
      <ls_find>-rldnr = ''.
      <ls_find>-docln = ''.

      IF <ls_find>-lifnr IS NOT INITIAL.
        FIND FIRST OCCURRENCE OF REGEX '[一-龥]' IN <ls_find>-lifnr.
        IF sy-subrc = 0.
          <ls_find>-delf = abap_true.
        ENDIF.
      ENDIF.


    ENDLOOP.




    TYPES: BEGIN OF ty_data,
             saknr   TYPE zfir090a-saknr,
             txt50   TYPE zfir090a-txt50,
             zfzxmlb TYPE zfir090a-zfzxmlb,
             saknr_f TYPE zfir090a-saknr,
             saknr_t TYPE zfir090a-saknr.
    TYPES: END OF ty_data.
    DATA: lt_zfir090a TYPE TABLE OF ty_data.

    SELECT *
    INTO TABLE @DATA(lt_t007s)
    FROM t007s
    WHERE spras = '1'
    AND kalsm = 'TAXCN'.


*    SELECT *
*    INTO CORRESPONDING FIELDS OF TABLE @lt_zfir090a
*    FROM zfir090a.

*    DATA:lv_num    TYPE i.
*    DATA:lv_string TYPE string.
*    DATA:lv_string_f TYPE string.
*    DATA:lv_string_t TYPE string.
*    DATA:lv_len TYPE i.
*    DATA: lv_n     TYPE i .
*    LOOP AT lt_zfir090a ASSIGNING FIELD-SYMBOL(<fs_zfir090a>).
*      CLEAR:lv_string,lv_string_f,lv_string_t,lv_len,lv_n .
*      lv_num = <fs_zfir090a>-saknr .
*      lv_string =  lv_num.
*      SHIFT lv_string LEFT DELETING LEADING '0'.
*      CONDENSE lv_string NO-GAPS.
*      lv_len =  strlen( lv_string ).
*      lv_n = 10 - lv_len .
*      lv_string_f  =  lv_string  && repeat( val = '0' occ = lv_n ).
*      lv_string_t  =  lv_string  && repeat( val = '9' occ = lv_n ).
*      <fs_zfir090a>-saknr_f = lv_string_f.
*      <fs_zfir090a>-saknr_t = lv_string_t.
*    ENDLOOP.



*    LOOP AT lt_find ASSIGNING FIELD-SYMBOL(<fs_find>).
*      LOOP AT lt_zfir090a INTO DATA(ls_zfir090a) WHERE  saknr_f <= <fs_find>-racct AND saknr_t >= <fs_find>-racct.
*        <fs_find>-ddtext = ls_zfir090a-zfzxmlb.
*        CONTINUE.
*      ENDLOOP.
*
*      IF <fs_find>-ddtext = 'AAC'."税
*        <fs_find>-fzx = <fs_find>-mwskz.
*        IF line_exists( lt_t007s[ mwskz = <fs_find>-mwskz ] ).
*          <fs_find>-fzxms = lt_t007s[ mwskz = <fs_find>-mwskz ]-text1.
*        ENDIF.
*      ELSEIF <fs_find>-ddtext = 'AAB'."客商
*        <fs_find>-fzx = <fs_find>-lifnr.
*        IF line_exists( lt_lfa1[ lifnr = <fs_find>-lifnr ] ).
*          <fs_find>-name1 = lt_lfa1[ lifnr = <fs_find>-lifnr ]-name.   "供应商的名字
*          <fs_find>-fzxms = <fs_find>-name1.
*        ELSE.
*          IF line_exists( lt_kna1[ kunnr = <fs_find>-lifnr ] ).
*            <fs_find>-name1 = lt_kna1[ kunnr = <fs_find>-lifnr ]-name.
*            <fs_find>-fzxms = <fs_find>-name1.
*          ENDIF.
*        ENDIF.
*      ELSEIF <fs_find>-ddtext = 'AAD'."职能范围
*        <fs_find>-fzx = <fs_find>-rfarea.
*        IF line_exists( lt_tfkbt[ fkber  =  <fs_find>-rfarea ] ).
*          <fs_find>-fzxms =  lt_tfkbt[ fkber  =  <fs_find>-rfarea ]-fkbtx.
*        ENDIF.
*      ENDIF.
*    ENDLOOP.




    DELETE me->lt_find WHERE delf = abap_true.
    " DELETE me->lt_find WHERE lifnr = ''.
    APPEND LINES OF me->lt_find TO lt_new_find.
    DELETE lt_new_find WHERE gjahr <> p_gjahr.
    DELETE lt_new_find WHERE poper > lv_delpoper.
    DELETE lt_new_find WHERE poper < lv_delpoplo.
    DELETE lt_new_find WHERE racct NOT IN s_racct.  "增加这个科目排除


*    SELECT FROM bseg AS b  ##ITAB_KEY_IN_SELECT
*          INNER JOIN @lt_find AS a
*          ON  a~rbukrs = b~bukrs
*          AND a~gjahr  = b~gjahr
*          AND a~belnr  = b~belnr
*          AND a~docln  = lpad( b~buzei, 6, '0' )
*          FIELDS
*          b~bukrs,
*          b~belnr,
*          b~gjahr,
*          lpad( b~buzei, 6, '0' ) AS buzei_6,
*          b~xnegp
*          INTO TABLE @DATA(lt_bsegnew).
*    IF sy-subrc = 0.
*      SORT lt_bsegnew BY bukrs belnr gjahr buzei_6.
*    ENDIF.

    SELECT FROM @lt_new_find AS a                           "mod-0001
     INNER JOIN  bseg AS b  ##ITAB_KEY_IN_SELECT
          ON  a~rbukrs = b~bukrs
          AND a~gjahr  = b~gjahr
          AND a~belnr  = b~belnr
          " 核心改动：使用 CAST 将 LPAD 的结果强制转换为 CHAR 6，与 DOCLN 完美握手
          AND a~buzei  = b~buzei
        FIELDS
          b~bukrs,
          b~belnr,
          b~gjahr,
          " SELECT 投影列里也同样使用 CAST 保证输出类型的严谨
          b~buzei,
          b~xnegp,
          b~shkzg
        INTO TABLE @DATA(lt_bsegnew).

    IF sy-subrc = 0.
      SORT lt_bsegnew BY bukrs belnr gjahr buzei.
    ENDIF.
    DATA:lv_datum TYPE sy-datum.

**    直接算期初 数据
    lv_datum = p_gjahr && s_monat-low && |01|.
    lv_datum = lv_datum - 1.


    SELECT FROM @me->lt_find AS a ##ITAB_KEY_IN_SELECT ##ITAB_DB_SELECT
      FIELDS
      a~rbukrs,
     " a~lifnr,
      a~racct,
*      a~ddtext,
*      a~fzx,
*       a~fzxms,
*       a~rwcur,
      a~rhcur
      WHERE a~gjahr <= @p_gjahr
*      GROUP BY a~rbukrs,  a~racct,a~ddtext,a~fzx, a~fzxms, a~rwcur, a~rhcur
*     ORDER BY a~rbukrs,  a~racct,a~ddtext,a~fzx, a~fzxms, a~rwcur, a~rhcur
      GROUP BY a~rbukrs,  a~racct,  a~rhcur
      ORDER BY a~rbukrs,  a~racct,  a~rhcur
      INTO TABLE @DATA(lt_order).

    LOOP AT lt_order INTO DATA(ls_order).
      ls_view_input-budat  = lv_datum.
      ls_view_input-gjahr  = p_gjahr.
      ls_view_input-poper  = s_monat-low.
      ls_view_input-racct  = ls_order-racct.
*      ls_view_input-ddtext  = ls_order-ddtext.
*      ls_view_input-fzx  = ls_order-fzx.
*      ls_view_input-fzxms  = ls_order-fzxms.
      ls_view_input-rbukrs = ls_order-rbukrs.
*      ls_view_input-rwcur  = ls_order-rwcur. "原币
      ls_view_input-rhcur  = ls_order-rhcur. "人民币
      COLLECT ls_view_input INTO lt_view_input.
      CLEAR:ls_view_input.
    ENDLOOP.

    IF s_waers-low = '*' . "如果选择屏幕不是人民币
    ELSE.
      IF c_zhbwb = ''.
        DELETE lt_view_input WHERE rwcur <> s_waers-low.
      ENDIF.
    ENDIF.

    DATA:lt_parallel_sum TYPE tt_find.
    DATA:ls_find_col TYPE ts_s_find.
    LOOP AT lt_view_input INTO ls_view_input.
      LOOP AT lt_find ASSIGNING <ls_find> WHERE  rbukrs = ls_view_input-rbukrs
                                         "   AND  lifnr  = ls_view_input-lifnr
                                            AND  racct  = ls_view_input-racct
*                                            AND  ddtext  = ls_view_input-ddtext
*                                            AND  fzx  = ls_view_input-fzx
*                                            AND  fzxms  = ls_view_input-fzxms
                                            AND  budat  <= ls_view_input-budat
*                                            AND  rwcur  = ls_view_input-rwcur
                                            AND  rhcur  = ls_view_input-rhcur.
        ls_find_col-rbukrs = <ls_find>-rbukrs.
        " ls_find_col-lifnr = <ls_find>-lifnr.
        ls_find_col-poper = ls_view_input-poper.
        ls_find_col-racct = <ls_find>-racct.
*        ls_find_col-ddtext = <ls_find>-ddtext.
*        ls_find_col-fzx = <ls_find>-fzx.
*        ls_find_col-fzxms = <ls_find>-fzxms.
*        ls_find_col-rwcur = <ls_find>-rwcur.
        ls_find_col-rhcur = <ls_find>-rhcur.
        ls_find_col-wsl   = <ls_find>-wsl.


        ls_find_col-hsl   = <ls_find>-hsl.
        COLLECT ls_find_col INTO lt_parallel_sum.
        CLEAR:ls_find_col.                                                     .
      ENDLOOP.

    ENDLOOP.


    CLEAR:lt_find.
    REFRESH:lt_find.



    SORT lt_parallel_sum BY rbukrs lifnr gjahr poper racct  rhcur . "这个不变

    SORT lt_new_find BY rbukrs lifnr gjahr poper racct budat.
    CLEAR: me->lt_alv_sum.

    LOOP AT lt_view_input INTO ls_view_input.

      APPEND INITIAL LINE TO me->lt_alv_sum ASSIGNING FIELD-SYMBOL(<ls_alv_sum>).
      <ls_alv_sum>-rbukrs = ls_view_input-rbukrs. "公司代码
      "   <ls_alv_sum>-lifnr  = ls_view_input-lifnr.   "供应商
      <ls_alv_sum>-racct  = ls_view_input-racct.
*      <ls_alv_sum>-ddtext  = ls_view_input-ddtext.
*      <ls_alv_sum>-fzx  = ls_view_input-fzx.
*      <ls_alv_sum>-fzxms  = ls_view_input-fzxms.


      READ TABLE lt_skat INTO DATA(ls_skat) WITH KEY saknr = <ls_alv_sum>-racct
                                           BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_alv_sum>-txt50 = ls_skat-txt50.
      ENDIF.


      <ls_alv_sum>-rwcur = ls_view_input-rwcur.
      <ls_alv_sum>-rhcur = ls_view_input-rhcur.

      READ TABLE lt_parallel_sum INTO DATA(ls_parallel_sum) WITH KEY  rbukrs = ls_view_input-rbukrs
                                                          "  lifnr  = ls_view_input-lifnr
                                                            racct  = ls_view_input-racct
*                                                            ddtext  = ls_view_input-ddtext
*                                                            fzx  = ls_view_input-fzx
*                                                            fzxms  = ls_view_input-fzxms
*                                                            rwcur  = ls_view_input-rwcur
                                                            rhcur  = ls_view_input-rhcur.
      IF sy-subrc = 0.
        IF ls_parallel_sum-hsl > 0.
          <ls_alv_sum>-qcybed = ls_parallel_sum-wsl.   " 期初原币额度
          <ls_alv_sum>-qcbbed = ls_parallel_sum-hsl."期初本币额度
          <ls_alv_sum>-drcrk = '借'.
        ELSEIF ls_parallel_sum-hsl < 0..
          <ls_alv_sum>-qcdfybed = ls_parallel_sum-wsl."期初贷方原币额度
          <ls_alv_sum>-qcdfbbed = ls_parallel_sum-hsl."期初贷方本币额度
          <ls_alv_sum>-drdfcrk = '贷'.
        ELSEIF ls_parallel_sum-hsl = 0..
          <ls_alv_sum>-qcdfybed = ls_parallel_sum-wsl."期初贷方原币额度
          <ls_alv_sum>-qcdfbbed = ls_parallel_sum-hsl."期初贷方本币额度
          <ls_alv_sum>-drdfcrk = '平'.
        ENDIF.

        IF <ls_alv_sum>-drcrk IS INITIAL.
          <ls_alv_sum>-drcrk = '平'.
        ENDIF.

*      期初原币余额 = 期初原币额度   借方期初               +   期初原币额度   贷方期初
        <ls_alv_sum>-qcybyenew  = <ls_alv_sum>-qcybed + <ls_alv_sum>-qcdfybed.

*      期初本币余额 = 期初本币额度   借方期初               +   期初本币额度   贷方期初
        <ls_alv_sum>-qcbbyenew  =  <ls_alv_sum>-qcbbed + <ls_alv_sum>-qcdfbbed.

        IF <ls_alv_sum>-qcbbyenew > 0.       "期初借贷标识
          <ls_alv_sum>-qcjdbiaos = '借'.
        ELSEIF <ls_alv_sum>-qcbbyenew < 0..
          <ls_alv_sum>-qcjdbiaos = '贷'.
        ELSE.
          <ls_alv_sum>-qcjdbiaos = '平'.
        ENDIF.

      ENDIF.


      DATA:lv_wsl_s TYPE acdoca-wsl,
           lv_hsl_s TYPE acdoca-hsl,
           lv_wsl_h TYPE acdoca-wsl,
           lv_hsl_h TYPE acdoca-hsl.

      CLEAR:
        lv_wsl_s,
        lv_hsl_s,
        lv_wsl_h,
        lv_hsl_h.

      LOOP AT lt_new_find INTO DATA(ls_new_find) WHERE  rbukrs = ls_view_input-rbukrs
                                                 "   AND  lifnr  = ls_view_input-lifnr
                                                    AND  racct  = ls_view_input-racct
*                                                    AND  ddtext  = ls_view_input-ddtext
*                                                    AND  fzx  = ls_view_input-fzx
*                                                    AND  fzxms  = ls_view_input-fzxms
*                                                    AND  rwcur  = ls_view_input-rwcur
                                                    AND  rhcur  = ls_view_input-rhcur.

        READ TABLE lt_bsegnew INTO DATA(ls_bsegnew) WITH KEY
         bukrs = ls_new_find-rbukrs
         gjahr = ls_new_find-gjahr
         belnr = ls_new_find-belnr
         buzei = ls_new_find-buzei
         BINARY SEARCH.                                     "mod-0001
        IF sy-subrc = 0 .
          IF ls_bsegnew-xnegp = 'X'.
            IF ls_bsegnew-shkzg = 'S'.
              lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
              lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
            ELSEIF ls_bsegnew-shkzg = 'H'.
              lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
              lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
            ENDIF.
          ELSE.
            IF ls_new_find-wsl >= 0.
              lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
            ELSE.
              lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
            ENDIF.

            IF ls_new_find-hsl >= 0.
              lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
            ELSE.
              lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
            ENDIF.
          ENDIF.
        ELSE.
          IF ls_new_find-wsl >= 0.
            lv_wsl_s = lv_wsl_s + ls_new_find-wsl.
          ELSE.
            lv_wsl_h = lv_wsl_h + ls_new_find-wsl.
          ENDIF.

          IF ls_new_find-hsl >= 0.
            lv_hsl_s = lv_hsl_s + ls_new_find-hsl.
          ELSE.
            lv_hsl_h = lv_hsl_h + ls_new_find-hsl.
          ENDIF.

        ENDIF.
        CLEAR:ls_bsegnew.


      ENDLOOP.

      <ls_alv_sum>-wsl    = lv_wsl_s.
      <ls_alv_sum>-dkfwsl = lv_wsl_h.

      <ls_alv_sum>-hsl    = lv_hsl_s.
      <ls_alv_sum>-dkfhsl = lv_hsl_h.

      <ls_alv_sum>-qmybed = <ls_alv_sum>-qcybed +  <ls_alv_sum>-qcdfybed
                                  + <ls_alv_sum>-wsl + <ls_alv_sum>-dkfwsl.

      <ls_alv_sum>-qmbbed = <ls_alv_sum>-qcbbed + <ls_alv_sum>-qcdfbbed
                                    + <ls_alv_sum>-hsl  + <ls_alv_sum>-dkfhsl.


      IF <ls_alv_sum>-qmybed > 0.
        <ls_alv_sum>-drcrkd = '借'.
      ELSEIF <ls_alv_sum>-qmybed < 0..
        <ls_alv_sum>-drcrkd = '贷'.
      ELSEIF <ls_alv_sum>-qmybed = 0..
        <ls_alv_sum>-drcrkd = '平'.
      ENDIF.

    ENDLOOP.


    LOOP AT lt_alv_sum ASSIGNING FIELD-SYMBOL(<fs_alv_sum>).
      IF <fs_alv_sum>-qcbbyenew > '0'.
        <fs_alv_sum>-qcjdbiaos = '借'.
      ELSEIF <fs_alv_sum>-qcbbyenew < '0'..
        <fs_alv_sum>-qcjdbiaos = '贷'.
      ELSE.
        <fs_alv_sum>-qcjdbiaos = '平'.
      ENDIF.

      IF <fs_alv_sum>-qmbbed > '0'.
        <fs_alv_sum>-drcrkd = '借'.
      ELSEIF <fs_alv_sum>-qmbbed < '0'. .
        <fs_alv_sum>-drcrkd = '贷'.
      ELSEIF <fs_alv_sum>-qmbbed = '0'. .
        <fs_alv_sum>-drcrkd = '平'.
      ENDIF.
    ENDLOOP.



  ENDMETHOD.



  METHOD display_list_of_players.
    DATA:temp_player TYPE REF TO player.
    LOOP AT players_list INTO temp_player.
      IF temp_player IS BOUND.
        IF ( c_fzx = 'X' AND c_zhbwb = '' )   OR ( c_fzx = 'X' AND c_zhbwb = 'X' ).
          temp_player->write_player_detailssum( ) .
          temp_player->write_player_show_sum_alv( it_alv = lt_alv_sum ).
          FREE temp_player.
        ELSEIF c_fzx = '' AND c_zhbwb = ''.
          temp_player->write_player_detailssum2( ) .
          temp_player->write_player_show_sum_alv( it_alv = lt_alv_sum ).
          FREE temp_player.
        ELSEIF c_fzx = '' AND c_zhbwb = 'X'."只勾选本位币
          temp_player->write_player_detailssum3( ) .
          temp_player->write_player_show_sum_alv( it_alv = lt_alv_sum ).
          FREE temp_player.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.





ENDCLASS.
