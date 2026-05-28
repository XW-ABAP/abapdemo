*&---------------------------------------------------------------------*
*& 包含               ZFIR088_LCL
*&---------------------------------------------------------------------*



*CLASS lcl_parallel_task DEFINITION.
*
*  PUBLIC SECTION.
*
*    TYPES:BEGIN OF ts_s_find,
*            rbukrs TYPE bukrs,         "公司代码
*            lifnr  TYPE lifnr,         "供应商编码
*            name1  TYPE txt120,      "供应商名称
*            gjahr  TYPE gjahr,         "年度
*            belnr  TYPE belnr_d,       "凭证编码
*            bktxt  TYPE bktxt,         "摘要
*            sgtxt  TYPE sgtxt,         "文本
*            budat  TYPE budat,         "过账日期
*            poper  TYPE poper,         "期间
*            racct  TYPE racct,         "总账科目
*            txt50  TYPE txt50_skat,    "科目描述
*            rwcur  TYPE fins_currw,    " 交易货币  usd    原币 币种
*            rhcur  TYPE fins_currh,    " 公司代码货币   人民币 币种
*            wsl    TYPE fins_vwcur12,  " 原币 金额
*            hsl    TYPE fins_vhcur12,  "人民币 金额
*            drcrk  TYPE shkzg,         "借贷标识
*            ebeln  TYPE ebeln,         "采购订单
*          END OF ts_s_find.
*    TYPES:ts_find TYPE ts_s_find.
*    TYPES:tt_find TYPE STANDARD TABLE OF ts_s_find .
*
*
*    TYPES:BEGIN OF ts_s_view,
*            rbukrs TYPE bukrs,
*            lifnr  TYPE lifnr,         "供应商编码
*            racct  TYPE racct,
*            gjahr  TYPE gjahr,         "年度
*            poper  TYPE poper,         "期间
*            budat  TYPE budat,         "
*            rwcur  TYPE fins_currw,
*            rhcur  TYPE fins_currh,
*            drcrk  TYPE shkzg,         "借贷标识
*            wsl    TYPE fins_vwcur12,    "本期原币 金额   借方
*            hsl    TYPE fins_vhcur12,    "本期人民币 金额 借方
*          END OF ts_s_view.
*    TYPES:tt_view TYPE TABLE OF ts_s_view,
*          ts_view TYPE ts_s_view.
*    DATA:ls_view TYPE ts_s_view,
*         lt_view TYPE TABLE OF ts_s_view.
*
*
*    DATA:lt_find TYPE tt_find.
*    DATA:
*       lt_return_sum TYPE TABLE OF ts_s_find.
*
*    INTERFACES if_abap_parallel.
*    METHODS constructor IMPORTING
*                          is_input TYPE ts_view
*                          it_find  TYPE tt_find.
*
*    CLASS-METHODS: get_different_money
*      IMPORTING is_input TYPE ts_view
*                it_find  TYPE tt_find
*      EXPORTING et_find  TYPE tt_find.
*
*    DATA:ls_input TYPE ts_view.
*
*ENDCLASS.
*
*
*
*CLASS lcl_parallel_task IMPLEMENTATION.
*
*  METHOD constructor.
*    super->constructor( ).
*    ls_input = is_input.
*    lt_find = it_find.
*  ENDMETHOD.
*
*
*  METHOD get_different_money.
*    DATA:ls_find_col TYPE ts_s_find.
*    IF is_input-rwcur IS NOT INITIAL AND  is_input-rwcur <> 'CNY'.
**      SELECT FROM @it_find AS a  ##ITAB_KEY_IN_SELECT ##ITAB_DB_SELECT
**        FIELDS
**          a~rbukrs,
**          a~lifnr ,
**          a~gjahr,
**          a~racct,
**          a~rwcur,
***          a~drcrk,
**         SUM( a~wsl ) AS wslnew
**        WHERE a~rbukrs = @is_input-rbukrs
**          AND a~lifnr  = @is_input-lifnr
**          AND a~racct  = @is_input-racct
**          AND a~budat  <= @is_input-budat
**          AND a~rwcur  = @is_input-rwcur
***          AND a~drcrk  = @is_input-drcrk
**        GROUP BY a~rbukrs, a~lifnr , a~gjahr, a~racct, a~rwcur
**        ORDER BY a~rbukrs, a~lifnr , a~gjahr, a~racct, a~rwcur
**        INTO TABLE @DATA(lt_data).
*
*      LOOP AT it_find ASSIGNING FIELD-SYMBOL(<ls_find>) WHERE  rbukrs = is_input-rbukrs
*                                                           AND  lifnr  = is_input-lifnr
*                                                           AND  racct  = is_input-racct
*                                                           AND  budat  <= is_input-budat
*                                                           AND  rwcur  = is_input-rwcur.
*        ls_find_col-rbukrs = <ls_find>-rbukrs.
*        ls_find_col-lifnr = <ls_find>-lifnr.
*        ls_find_col-gjahr = <ls_find>-gjahr.
*        ls_find_col-poper = <ls_find>-poper.
*        ls_find_col-racct = <ls_find>-racct.
**        ls_find_col-drcrk = is_input-drcrk.
*        ls_find_col-rwcur = <ls_find>-rwcur.
*        ls_find_col-wsl   = <ls_find>-wsl.
*        COLLECT ls_find_col INTO et_find.
*        CLEAR:ls_find_col.                                                     .
*      ENDLOOP.
*
**      LOOP AT lt_data INTO DATA(ls_data).
**        ls_find_col-rbukrs = is_input-rbukrs.
**        ls_find_col-lifnr = is_input-lifnr.
**        ls_find_col-gjahr = is_input-gjahr.
**        ls_find_col-poper = is_input-poper.
**        ls_find_col-racct = is_input-racct.
***        ls_find_col-drcrk = is_input-drcrk.
**        ls_find_col-rwcur = is_input-rwcur.
**        ls_find_col-wsl   = ls_data-wslnew.
**        COLLECT ls_find_col INTO et_find.
**        CLEAR:ls_find_col.
**      ENDLOOP.
*    ELSEIF is_input-rhcur IS NOT INITIAL.
**      SELECT FROM @it_find AS a        ##ITAB_KEY_IN_SELECT ##ITAB_DB_SELECT
**        FIELDS
**          a~rbukrs,
**          a~lifnr ,
**          a~gjahr,
**          a~racct,
**          a~rhcur,
***          a~drcrk,
**         SUM( a~hsl ) AS wslnew
**        WHERE a~rbukrs = @is_input-rbukrs
**          AND a~lifnr  = @is_input-lifnr
**          AND a~racct  = @is_input-racct
**          AND a~budat  <= @is_input-budat
**          AND a~rhcur  = @is_input-rhcur
***          AND a~drcrk  = @is_input-drcrk
**        GROUP BY a~rbukrs, a~lifnr , a~gjahr, a~racct, a~rhcur
**        ORDER BY a~rbukrs, a~lifnr , a~gjahr, a~racct, a~rhcur
**        INTO TABLE @DATA(lt_data1).
**
**      LOOP AT lt_data1 INTO DATA(ls_data1).
**        ls_find_col-rbukrs = is_input-rbukrs.
**        ls_find_col-lifnr = is_input-lifnr.
**        ls_find_col-gjahr = is_input-gjahr.
**        ls_find_col-poper = is_input-poper.
**        ls_find_col-racct = is_input-racct.
***        ls_find_col-drcrk = is_input-drcrk.
**        ls_find_col-rhcur = is_input-rhcur.
**        ls_find_col-hsl   = ls_data1-wslnew.
**
**        COLLECT ls_find_col INTO et_find.
**        CLEAR:ls_find_col.
**      ENDLOOP.
**
*
*
*      LOOP AT it_find ASSIGNING <ls_find> WHERE  rbukrs = is_input-rbukrs
*                                                        AND  lifnr  = is_input-lifnr
*                                                        AND  racct  = is_input-racct
*                                                        AND  budat  <= is_input-budat
*                                                        AND  rhcur  = is_input-rhcur.
*        ls_find_col-rbukrs = <ls_find>-rbukrs.
*        ls_find_col-lifnr = <ls_find>-lifnr.
*        ls_find_col-gjahr = <ls_find>-gjahr.
*        ls_find_col-poper = <ls_find>-poper.
*        ls_find_col-racct = <ls_find>-racct.
**        ls_find_col-drcrk = is_input-drcrk.
*        ls_find_col-rhcur = <ls_find>-rhcur.
*        ls_find_col-hsl   = <ls_find>-hsl.
*        COLLECT ls_find_col INTO et_find.
*        CLEAR:ls_find_col.                                                     .
*      ENDLOOP.
*
*    ENDIF.
*
*
*  ENDMETHOD.
*
*
*  METHOD if_abap_parallel~do.
*
*    CALL METHOD get_different_money
*      EXPORTING
*        is_input = ls_input
*        it_find  = lt_find
*      IMPORTING
*        et_find  = DATA(lt_result).
*    IF lt_result[] IS NOT INITIAL.
*      APPEND LINES OF lt_result TO lt_return_sum.
*    ENDIF.
*
*  ENDMETHOD.
*ENDCLASS.




*CLASS lcl_parallel_inst DEFINITION.
*  PUBLIC SECTION.
*
*    TYPES:BEGIN OF ts_s_view,
*            rbukrs TYPE bukrs,
*            lifnr  TYPE lifnr,         "供应商编码
*            racct  TYPE racct,
*            gjahr  TYPE gjahr,         "年度
*            poper  TYPE poper,         "期间
*            budat  TYPE budat,         "
*            rwcur  TYPE fins_currw,
*            rhcur  TYPE fins_currh,
*            drcrk  TYPE shkzg,         "借贷标识
*            wsl    TYPE fins_vwcur12,    "本期原币 金额   借方
*            hsl    TYPE fins_vhcur12,    "本期人民币 金额 借方
*          END OF ts_s_view.
*    TYPES:tt_view TYPE TABLE OF ts_s_view,
*          ts_view TYPE ts_s_view.
*
*    TYPES:BEGIN OF ts_s_find,
*            rbukrs TYPE bukrs,         "公司代码
*            lifnr  TYPE lifnr,         "供应商编码
*            name1  TYPE text120,      "供应商名称
*            gjahr  TYPE gjahr,         "年度
*            belnr  TYPE belnr_d,       "凭证编码
*            bktxt  TYPE bktxt,         "摘要
*            sgtxt  TYPE sgtxt,         "文本
*            budat  TYPE budat,         "过账日期
*            poper  TYPE poper,         "期间
*            racct  TYPE racct,         "总账科目
*            txt50  TYPE txt50_skat,    "科目描述
*            rwcur  TYPE fins_currw,    " 交易货币  usd    原币 币种
*            rhcur  TYPE fins_currh,    " 公司代码货币   人民币 币种
*            wsl    TYPE fins_vwcur12,  " 原币 金额
*            hsl    TYPE fins_vhcur12,  "人民币 金额
*            drcrk  TYPE shkzg,         "借贷标识
*            ebeln  TYPE ebeln,         "采购订单
*          END OF ts_s_find.
*    TYPES:tt_find TYPE TABLE OF ts_s_find.
*
*    CLASS-DATA:lt_find  TYPE tt_find.
*
*    CLASS-METHODS start
*      IMPORTING it_inputs TYPE tt_view
*                it_finds  TYPE tt_find
*      EXPORTING et_finds  TYPE tt_find.
*ENDCLASS.
*
*
*
*CLASS lcl_parallel_inst IMPLEMENTATION.
*  METHOD start.
*
*    DATA:
*      l_in_tab TYPE cl_abap_parallel=>t_in_inst_tab,
*      l_inst   TYPE REF TO lcl_parallel_task.
*
*    DATA(l_ref) = NEW cl_abap_parallel( ).
*
*
*    LOOP AT it_inputs INTO DATA(ls_input).
*      APPEND NEW lcl_parallel_task( is_input = ls_input
*                                    it_find  = it_finds
*                                    ) TO l_in_tab.
*    ENDLOOP.
*
*    DATA:lv_debug TYPE abap_bool.
*
*    CLEAR:lv_debug.
*
*    l_ref->run_inst( EXPORTING p_in_tab  = l_in_tab
*                               p_debug   = lv_debug
*                     IMPORTING p_out_tab = DATA(l_out_tab) ).
*
*
*    LOOP AT l_out_tab ASSIGNING FIELD-SYMBOL(<l_out>) WHERE inst IS NOT INITIAL.
*      l_inst ?= <l_out>-inst.
*      APPEND LINES OF l_inst->lt_return_sum TO et_finds.
*    ENDLOOP.
*  ENDMETHOD.
*ENDCLASS.


CLASS player DEFINITION DEFERRED.
TYPES: ty_player TYPE REF TO player.


CLASS cx_my_exception DEFINITION INHERITING FROM cx_static_check.
ENDCLASS.


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
            buzei  TYPE buzei,                              "mod-0001
*            fpbelnr TYPE belnr_d,      "发票凭证            "mod-0002
            zz002  TYPE zepic_invoice, "发票号码
          END OF ts_s_find.
    TYPES:tt_find TYPE TABLE OF ts_s_find.

    TYPES:BEGIN OF ts_s_alvplay,
            rbukrs  TYPE bukrs,           "公司代码
            lifnr   TYPE lifnr,           "供应商编码
            name1   TYPE txt120,        "供应商名称
            gork    TYPE txt20,           "供应商还是客商
            gjahr   TYPE gjahr,           "年度
            poper   TYPE poper,           "期间
            racct   TYPE racct,           "总账科目
            budat   TYPE budat,           "过账日期
            txt50   TYPE txt50_skat,      "科目描述
            belnr   TYPE belnr_d,         "凭证编码
            hfc_doc TYPE zhfc_doc,        "HFC会计凭证编号
            bktxt   TYPE bktxt,           "摘要
            begwsl  TYPE fins_vwcur12,    "期初原币金额
            beghsl  TYPE fins_vhcur12,    "期初本币金额
            rwcur   TYPE fins_currw,      "交易货币  usd    原币 币种
            rhcur   TYPE fins_currh,      "公司代码货币   人民币 币种
            wsl     TYPE fins_vwcur12,    "本期原币 金额   借方
            hsl     TYPE fins_vhcur12,    "本期人民币 金额 借方
            dkfwsl  TYPE fins_vwcur12,    "本期原币金额   贷方
            dkfhsl  TYPE fins_vhcur12,    "本期人民币金额  贷方
            drcrkd  TYPE shkzg,           "当前数据的 借贷标识   借方/贷方
            endwsl  TYPE fins_vwcur12,    "期末原币金额
            endhsl  TYPE fins_vhcur12,    "期末本币金额
            drcrkt  TYPE char1,           "借贷标识中文
            ebeln   TYPE ebeln,           "采购订单编码
            zz002   TYPE zepic_invoice,   "发票号
            t_color TYPE lvc_t_scol,  " <--- 【必须改为这个标准类型】
          END OF ts_s_alvplay.

    TYPES:tt_alv_play TYPE TABLE OF ts_s_alvplay.
    CLASS-DATA: ls_alv_display TYPE ts_s_alvplay.

    CLASS-DATA: lt_alv_display TYPE tt_alv_play.

    TYPES:BEGIN OF ts_s_alvsum,
            rbukrs    TYPE bukrs,           "公司代码
            lifnr     TYPE lifnr,           "供应商编码
            name1     TYPE txt120,          "供应商名称
            gork      TYPE txt20,           "供应商还是客商
            racct     TYPE racct,           "总账科目
            txt50     TYPE txt50_skat,      "科目描述
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
            qcjdbst   TYPE char1,          "期初借贷标识中文
*          add new  field end
            wsl       TYPE fins_vwcur12,    "本期原币 金额   借方
            hsl       TYPE fins_vhcur12,    "本期人民币 金额 借方
            dkfwsl    TYPE fins_vwcur12,   "本期原币金额   贷方
            dkfhsl    TYPE fins_vhcur12,    "本期人民币金额  贷方
            qmybed    TYPE fins_vwcur12,    "期末原币额度
            qmbbed    TYPE fins_vwcur12,    "期末本币额度
            drcrkd    TYPE shkzg,           "当前数据的 借贷标识   借方/贷方
            drcrkt    TYPE char1,           "借贷标识中文
          END OF ts_s_alvsum.

    TYPES:tt_alv_sum TYPE TABLE OF ts_s_alvsum.
    TYPES:ts_alv_sum TYPE ts_s_alvsum.
    CLASS-DATA: ls_alv_sum TYPE ts_alv_sum.
    CLASS-DATA: lt_alv_sum TYPE tt_alv_sum.

    DATA: gr_table TYPE REF TO cl_salv_table.
    DATA: gr_columns TYPE REF TO cl_salv_columns_table.
    DATA: gr_column TYPE REF TO cl_salv_column_table.
    DATA: gr_layout TYPE REF TO cl_salv_layout.
    DATA: gs_program TYPE salv_s_layout_key.
    DATA: gr_selection TYPE REF TO cl_salv_selections.

    METHODS write_player_details.


    METHODS write_player_details_new
      IMPORTING it_find_new TYPE tt_find.

    METHODS write_player_show_detail_alv
      IMPORTING it_alv TYPE tt_alv_play.


    METHODS write_player_detailssum.


    METHODS write_player_show_sum_alv
      IMPORTING it_alv TYPE tt_alv_sum.


    METHODS constructor IMPORTING iv_tbname    TYPE tabname
                                  iv_condition TYPE text10
                        RAISING   cx_my_exception.
    CLASS-METHODS: display_list_of_players.


    METHODS:
      on_hotspot_click FOR EVENT link_click OF cl_salv_events_table IMPORTING row column.

  PRIVATE SECTION.


    DATA:lt_find      TYPE TABLE OF ts_s_find,
         ls_find      TYPE ts_s_find,
         lt_findk     TYPE TABLE OF ts_s_find,
         ls_findk     TYPE ts_s_find,
         lt_findbug   TYPE TABLE OF ts_s_find,
         ls_findbug   TYPE ts_s_find,
         ls_alvplay   TYPE ts_s_alvplay,
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
          END OF ts_s_view.
    TYPES:tt_view TYPE TABLE OF ts_s_view,
          ts_view TYPE ts_s_view.

    CLASS-DATA: players_list TYPE STANDARD TABLE OF ty_player.
ENDCLASS.


CLASS player IMPLEMENTATION.
  METHOD constructor.


    IF iv_condition = 'P1'.                                 "MOD-0002
      IF s_waers-low = '*'.
        MESSAGE '客商辅助明细表币别请指定，例如RMB!' TYPE 'S' DISPLAY LIKE 'E'.
        RAISE EXCEPTION TYPE cx_my_exception.
      ENDIF.
    ENDIF.

    IF r_btn1 = 'X' OR  r_btn3 = 'X'.                       "mod-0001

*    捞取供应商数据   begin
      GET REFERENCE OF me->lt_find INTO me->lr_result.
      LOOP AT s_monat INTO DATA(ls_monat).
        me->lt_poper = VALUE #( BASE me->lt_poper (  sign = 'I' option = 'EQ' low = |0| && ls_monat-low high = |0| && ls_monat-high ) ).
      ENDLOOP.

      lv_condition = iv_condition.

      me->lv_tabname = iv_tbname.

      me->lv_where =  | gjahr <= '{ p_gjahr }' and blart <> '' and  rclnt = '{ sy-mandt }' and rldnr = '0L' | .

*   转换range变成where条件   begin
      TRY.
          DATA(lv_where_clause) = cl_shdb_seltab=>combine_seltabs(
                                   it_named_seltabs = VALUE #(
                                     ( name = 'RACCT'  dref = REF #( s_racct[] ) )
                                     ( name = 'LIFNR'  dref = REF #( s_lifnr[] ) )
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
                         | racct, '' as TXT50, rwcur, rhcur, wsl, hsl, drcrk, ebeln, '' as DELF, buzei, zz002 | &&
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
    ENDIF.
*捞取供应商数据   end

    IF r_btn1 = 'X' OR  r_btn2 = 'X'.                       "mod-0001
***捞取客户数据  begin

      GET REFERENCE OF me->lt_findk INTO me->lr_resultk.
*    LOOP AT s_monat INTO DATA(ls_monat).
*      me->lt_poper = VALUE #( BASE me->lt_poper (  sign = 'I' option = 'EQ' low = |0| && ls_monat-low high = |0| && ls_monat-high ) ).
*    ENDLOOP.

      CLEAR:me->lv_where.

      lv_condition = iv_condition.

      me->lv_tabname = iv_tbname.

      me->lv_where =  | gjahr <= '{ p_gjahr }' and blart <> '' and  rclnt = '{ sy-mandt }' | .

*   转换range变成where条件   begin
      CLEAR:lv_where_clause.
      TRY.
          lv_where_clause = cl_shdb_seltab=>combine_seltabs(
                                   it_named_seltabs = VALUE #(
                                     ( name = 'RACCT'  dref = REF #( s_racct[] ) )
                                     ( name = 'KUNNR'  dref = REF #( s_kunnr[] ) )
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
                         | racct, '' as TXT50, rwcur, rhcur, wsl, hsl, drcrk, ebeln, '' as DELF, buzei, zz002 | &&
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

***捞取客户数据  end


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
                        |and  racct = '2202030100'|.
        CLEAR:lv_where_clause.

*   转换range变成where条件   begin
        TRY.
            lv_where_clause = cl_shdb_seltab=>combine_seltabs(
                                     it_named_seltabs = VALUE #(
*                                     ( name = 'RACCT'  dref = REF #( s_racct[] ) )
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
                           | racct, '' as TXT50, rwcur, rhcur, wsl, hsl, drcrk, ebeln, '' as DELF, buzei, zz002 | &&
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

        DELETE me->lt_findbug WHERE lifnr NOT IN s_lifnr.

      ENDIF.

    ENDIF.

    APPEND me TO players_list.
  ENDMETHOD.






  METHOD write_player_details_new.

    CLEAR:me->lt_alv_display.

    DATA(lt_find_new) = it_find_new.

    " --- 新增：定义用于追踪分组的哈希表 ---
    TYPES: tt_processed_keys TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
    DATA: lt_processed_keys TYPE tt_processed_keys.

    " --- 定义辅助颜色结构 ---
    DATA: lt_s_color TYPE lvc_t_scol,
          ls_s_color TYPE lvc_s_scol.

    " =====================================================================
    " 1. 【核心防御】前台条件强行清洗底层脏数据 (杜绝跨币种污染)
    " =====================================================================
    IF s_waers[] IS NOT INITIAL.
      DELETE lt_find_new WHERE rwcur NOT IN s_waers.
    ENDIF.
    IF s_racct[] IS NOT INITIAL.
      DELETE lt_find_new WHERE racct NOT IN s_racct.
    ENDIF.

    TYPES: BEGIN OF ty_beg_bal,
             rbukrs TYPE acdoca-rbukrs,
             lifnr  TYPE acdoca-lifnr,
             racct  TYPE acdoca-racct,
             rwcur  TYPE acdoca-rwcur,
             rhcur  TYPE acdoca-rhcur,
             beghsl TYPE acdoca-hsl,
             begwsl TYPE acdoca-wsl,
           END OF ty_beg_bal.

    DATA: lt_beg_bal       TYPE TABLE OF ty_beg_bal,
          lt_final_display TYPE TABLE OF ts_s_alvplay,
          ls_sum_month     TYPE ts_s_alvplay,
          ls_sum_year      TYPE ts_s_alvplay.

    DATA: lv_delpoplo TYPE poper,
          lv_delpoper TYPE poper.

    READ TABLE s_monat INTO DATA(ls_monat) INDEX 1.
    IF sy-subrc = 0.
      lv_delpoplo = ls_monat-low.
      lv_delpoper = ls_monat-high.
      IF lv_delpoper IS INITIAL.
        lv_delpoper = ls_monat-low.
      ENDIF.
      IF lv_delpoper > '12'.
        lv_delpoper = '12'.
      ENDIF.
    ENDIF.

    " =====================================================================
    " 2. 极速捞取“期初余额”
    " =====================================================================
    SELECT rbukrs, lifnr, kunnr, racct, rwcur, rhcur,
           SUM( hsl ) AS beghsl,
           SUM( wsl ) AS begwsl
      FROM acdoca
     WHERE rbukrs IN @s_bukrs
       AND lifnr  IN @s_lifnr
       AND kunnr  IN @s_kunnr
       AND rwcur  IN @s_waers
       AND ( gjahr < @p_gjahr OR ( gjahr = @p_gjahr AND poper < @lv_delpoplo ) )
      " ▼ 核心邏輯修改：使用括號將兩種情況包起來
*       AND ( ( racct IN @s_racct AND racct <> '2202030100' ) OR
*           ( racct = '2202030100' AND lifnr = @space ) )
      AND racct IN @s_racct
      AND NOT ( racct = '2202030100' AND lifnr <> @space )
     GROUP BY rbukrs, lifnr, kunnr, racct, rwcur, rhcur
      INTO TABLE @DATA(lt_beg_bal_raw).

    LOOP AT lt_beg_bal_raw INTO DATA(ls_raw).
      DATA(ls_beg) = VALUE ty_beg_bal( rbukrs = ls_raw-rbukrs
                                       racct  = ls_raw-racct
                                       rwcur  = ls_raw-rwcur
                                       rhcur  = ls_raw-rhcur
                                       beghsl = ls_raw-beghsl
                                       begwsl = ls_raw-begwsl ).
      IF ls_raw-lifnr IS NOT INITIAL.
        ls_beg-lifnr = ls_raw-lifnr.
      ELSE.
        ls_beg-lifnr = ls_raw-kunnr.
      ENDIF.
      COLLECT ls_beg INTO lt_beg_bal.
    ENDLOOP.

    SORT lt_beg_bal BY rbukrs lifnr racct rwcur rhcur.

    " =====================================================================
    " 3. 准备各类基础数据
    " =====================================================================
    SELECT FROM zfit_ofn AS a
      FIELDS a~bukrs, a~hfc_doc, a~belnr, a~gjahr, a~monat
      WHERE a~bukrs IN @s_bukrs
        AND a~gjahr = @p_gjahr
      INTO TABLE @DATA(lt_zfit_ofn).
    IF sy-subrc = 0. SORT lt_zfit_ofn BY bukrs gjahr belnr. ENDIF.

    SELECT FROM lfa1 AS a
      FIELDS a~lifnr, concat( a~name1, concat( a~name2, a~name3 ) ) AS name
      ORDER BY lifnr INTO TABLE @DATA(lt_lfa1).

    SELECT FROM kna1 AS a
      FIELDS a~kunnr, concat( a~name1, a~name2 ) AS name
      ORDER BY kunnr INTO TABLE @DATA(lt_kna1).

    SELECT * FROM zc_hkont_detail_tf( iv_ktopl = '1000', iv_saknr = '0000000000', iv_spras = '1' )
      INTO TABLE @DATA(lt_skat).
    SORT lt_skat BY ktopl saknr.

    IF me->lt_findk IS NOT INITIAL. APPEND LINES OF me->lt_findk TO me->lt_find. CLEAR: me->lt_findk. ENDIF.
    IF me->lt_findbug IS NOT INITIAL. APPEND LINES OF me->lt_findbug TO me->lt_find. CLEAR: me->lt_findbug. ENDIF.

    DELETE me->lt_find WHERE lifnr = ''.
    SORT me->lt_find BY rldnr rbukrs gjahr belnr docln racct lifnr.
    DELETE ADJACENT DUPLICATES FROM me->lt_find COMPARING rldnr rbukrs gjahr belnr docln racct lifnr.

    DATA: lv_zhuanh TYPE p DECIMALS 3.
    LOOP AT lt_find_new ASSIGNING FIELD-SYMBOL(<ls_find>).
      CLEAR: lv_zhuanh.
      CALL FUNCTION 'CURRENCY_CONVERTING_FACTOR'
        EXPORTING
          currency          = <ls_find>-rwcur
        IMPORTING
          factor            = lv_zhuanh
        EXCEPTIONS
          too_many_decimals = 1
          OTHERS            = 2.
      IF sy-subrc = 0. <ls_find>-wsl = <ls_find>-wsl * lv_zhuanh. ENDIF.
      <ls_find>-rldnr = ''. <ls_find>-docln = ''.

      IF <ls_find>-lifnr IS NOT INITIAL.
        FIND FIRST OCCURRENCE OF REGEX '[一-龥]' IN <ls_find>-lifnr.
        IF sy-subrc = 0. <ls_find>-delf = abap_true. ENDIF.
      ENDIF.
    ENDLOOP.

*    DELETE lt_find_new WHERE delf = abap_true.
*    DELETE lt_find_new WHERE lifnr = ''.
*    DELETE lt_find_new WHERE gjahr <> p_gjahr.
*    DELETE lt_find_new WHERE poper > lv_delpoper.
*    DELETE lt_find_new WHERE poper < lv_delpoplo.


    DELETE lt_find_new WHERE delf = abap_true
                          OR lifnr = ''
                          OR gjahr <> p_gjahr
                          OR poper > lv_delpoper
                          OR poper < lv_delpoplo.


    SELECT FROM @lt_find_new AS a
      INNER JOIN bseg AS b ##ITAB_KEY_IN_SELECT
         ON a~rbukrs = b~bukrs AND a~gjahr  = b~gjahr AND a~belnr  = b~belnr AND a~buzei  = b~buzei
      FIELDS b~bukrs, b~belnr, b~gjahr, b~buzei, b~xnegp, b~shkzg
      INTO TABLE @DATA(lt_bsegnew).
    IF sy-subrc = 0. SORT lt_bsegnew BY bukrs belnr gjahr buzei. ENDIF.

    " =====================================================================
    " 4. 映射到展示内表
    " =====================================================================
    LOOP AT lt_find_new ASSIGNING <ls_find>.
      APPEND INITIAL LINE TO lt_alv_display ASSIGNING FIELD-SYMBOL(<ls_alv_display>).
      <ls_alv_display>-rbukrs = <ls_find>-rbukrs.
      <ls_alv_display>-lifnr  = <ls_find>-lifnr.

      READ TABLE lt_lfa1 INTO DATA(ls_lfa1) WITH KEY lifnr = <ls_find>-lifnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_alv_display>-name1 = ls_lfa1-name. <ls_alv_display>-gork  = '供应商'.
      ELSE.
        READ TABLE lt_kna1 INTO DATA(ls_kna1) WITH KEY kunnr = <ls_find>-lifnr BINARY SEARCH.
        IF sy-subrc = 0.
          <ls_alv_display>-name1 = ls_kna1-name. <ls_alv_display>-gork  = '客户'.
        ENDIF.
      ENDIF.

      <ls_alv_display>-gjahr  = <ls_find>-gjahr.
      <ls_alv_display>-poper  = <ls_find>-poper.
      <ls_alv_display>-racct  = <ls_find>-racct.
      <ls_alv_display>-budat  = <ls_find>-budat.

      READ TABLE lt_skat INTO DATA(ls_skat) WITH KEY saknr = <ls_find>-racct BINARY SEARCH.
      IF sy-subrc = 0. <ls_alv_display>-txt50 = ls_skat-txt50. ENDIF.

      <ls_alv_display>-belnr  = <ls_find>-belnr.

      READ TABLE lt_zfit_ofn INTO DATA(ls_zfit_ofn) WITH KEY bukrs = <ls_find>-rbukrs gjahr = <ls_find>-gjahr belnr = <ls_find>-belnr BINARY SEARCH.
      IF sy-subrc = 0. <ls_alv_display>-hfc_doc = ls_zfit_ofn-hfc_doc. ENDIF.

      <ls_alv_display>-bktxt  = <ls_find>-bktxt.
      <ls_alv_display>-rwcur  = <ls_find>-rwcur.
      <ls_alv_display>-rhcur  = <ls_find>-rhcur.

      READ TABLE lt_bsegnew INTO DATA(ls_bsegnew) WITH KEY bukrs = <ls_find>-rbukrs gjahr = <ls_find>-gjahr belnr = <ls_find>-belnr buzei = <ls_find>-buzei BINARY SEARCH.
      IF sy-subrc = 0.
        IF ls_bsegnew-xnegp = 'X'.
          IF ls_bsegnew-shkzg = 'S'.
            <ls_alv_display>-dkfwsl = <ls_find>-wsl. <ls_alv_display>-dkfhsl = <ls_find>-hsl.
          ELSEIF ls_bsegnew-shkzg = 'H'.
            <ls_alv_display>-wsl    = <ls_find>-wsl. <ls_alv_display>-hsl    = <ls_find>-hsl.
          ENDIF.
        ELSE.
          IF <ls_find>-hsl >= 0.
            <ls_alv_display>-wsl    = <ls_find>-wsl. <ls_alv_display>-hsl    = <ls_find>-hsl.
          ELSE.
            <ls_alv_display>-dkfwsl = <ls_find>-wsl. <ls_alv_display>-dkfhsl = <ls_find>-hsl.
          ENDIF.
        ENDIF.
      ELSE.
        IF <ls_find>-hsl >= 0.
          <ls_alv_display>-wsl    = <ls_find>-wsl. <ls_alv_display>-hsl    = <ls_find>-hsl.
        ELSE.
          <ls_alv_display>-dkfwsl = <ls_find>-wsl. <ls_alv_display>-dkfhsl = <ls_find>-hsl.
        ENDIF.
      ENDIF.
      <ls_alv_display>-drcrkd = <ls_find>-drcrk.
    ENDLOOP.

    " =====================================================================
    " 5. 【严控排序与独立账本滚算】
    " =====================================================================
    SORT lt_alv_display BY rbukrs ASCENDING
                           lifnr  ASCENDING
                           racct  ASCENDING
                           rwcur  ASCENDING
                           rhcur  ASCENDING
                           gjahr  ASCENDING
                           poper  ASCENDING.

    TYPES: BEGIN OF ty_run_bal,
             key    TYPE string,
             beghsl TYPE fins_vhcur12,
             begwsl TYPE fins_vwcur12,
           END OF ty_run_bal.
    DATA: lt_run_bal   TYPE HASHED TABLE OF ty_run_bal WITH UNIQUE KEY key,
          lv_curr_key  TYPE string,
          ls_beg_match TYPE ty_beg_bal.

    LOOP AT lt_alv_display ASSIGNING FIELD-SYMBOL(<ls_calc>).
      lv_curr_key = |{ <ls_calc>-rbukrs }-{ <ls_calc>-lifnr }-{ <ls_calc>-racct }-{ <ls_calc>-rwcur }-{ <ls_calc>-rhcur }|.

      READ TABLE lt_run_bal ASSIGNING FIELD-SYMBOL(<ls_run_bal>) WITH TABLE KEY key = lv_curr_key.
      IF sy-subrc <> 0.
        DATA(ls_new_bal) = VALUE ty_run_bal( key = lv_curr_key ).
        READ TABLE lt_beg_bal INTO ls_beg_match
             WITH KEY rbukrs = <ls_calc>-rbukrs
                      lifnr  = <ls_calc>-lifnr
                      racct  = <ls_calc>-racct
                      rwcur  = <ls_calc>-rwcur
                      rhcur  = <ls_calc>-rhcur BINARY SEARCH.
        IF sy-subrc = 0.
          ls_new_bal-beghsl = ls_beg_match-beghsl.
          ls_new_bal-begwsl = ls_beg_match-begwsl.
        ENDIF.
        INSERT ls_new_bal INTO TABLE lt_run_bal ASSIGNING <ls_run_bal>.
      ENDIF.

      <ls_calc>-beghsl = <ls_run_bal>-beghsl.
      <ls_calc>-begwsl = <ls_run_bal>-begwsl.

      <ls_calc>-endhsl = <ls_calc>-beghsl + <ls_calc>-hsl - <ls_calc>-dkfhsl.
      <ls_calc>-endwsl = <ls_calc>-begwsl + <ls_calc>-wsl - <ls_calc>-dkfwsl.

      IF <ls_calc>-endhsl > 0.
        <ls_calc>-drcrkt = '借'.
      ELSEIF <ls_calc>-endhsl < 0.
        <ls_calc>-drcrkt = '贷'.
      ELSE.
        <ls_calc>-drcrkt = '平'.
      ENDIF.

      <ls_run_bal>-beghsl = <ls_calc>-endhsl.
      <ls_run_bal>-begwsl = <ls_calc>-endwsl.
    ENDLOOP.

    " =====================================================================
    " 6. 【终极修复】镜像追踪法：彻底告别计算偏差与串行
    " =====================================================================
    CLEAR lt_final_display.
    CLEAR: ls_sum_month, ls_sum_year.

    DATA: lv_is_new_month TYPE abap_bool VALUE abap_true,
          lv_is_new_year  TYPE abap_bool VALUE abap_true.

    DATA: lv_month_beghsl TYPE fins_vhcur12,
          lv_month_begwsl TYPE fins_vwcur12,
          lv_year_beghsl  TYPE fins_vhcur12,
          lv_year_begwsl  TYPE fins_vwcur12.

    LOOP AT lt_alv_display INTO DATA(ls_current).

      " ！！！【核心修复】！！！
      " 必须在进入循环的第一步立刻抓取 sy-tabix。
      " 因为后面的 INSERT 会把 sy-tabix 刷成 0，导致下一行判断错乱。
      DATA(lv_current_index) = sy-tabix.

      " --- 新增：插入期初余额的逻辑 ---
      DATA(lv_group_key) = |{ ls_current-rbukrs }-{ ls_current-lifnr }-{ ls_current-racct }-{ ls_current-rwcur }-{ ls_current-gjahr }-{ ls_current-poper }|.

      IF NOT line_exists( lt_processed_keys[ table_line = lv_group_key ] ).
        " 1. 构造期初行
        DATA: ls_opening TYPE ts_s_alvplay.
        ls_opening-bktxt = '期初余额'.
        ls_opening-endhsl = ls_current-beghsl.
        ls_opening-endwsl = ls_current-begwsl.

        " 设置期初余额的借贷方向
        IF ls_opening-endhsl > 0.
          ls_opening-drcrkt = '借'.
        ELSEIF ls_opening-endhsl < 0.
          ls_opening-drcrkt = '贷'.
        ELSE.
          ls_opening-drcrkt = '平'.
        ENDIF.

        " 2. 插入到最终输出表
        APPEND ls_opening TO lt_final_display.

        " 3. 标记该分组已插入
        INSERT lv_group_key INTO TABLE lt_processed_keys.
      ENDIF.
      " ---------------------------------

      " --- 绝对准确的期初抓取：只抓每一段跳变的【第一行】的期初 ---
      IF lv_is_new_year = abap_true.
        lv_year_beghsl = ls_current-beghsl.
        lv_year_begwsl = ls_current-begwsl.
        lv_is_new_year = abap_false.
      ENDIF.

      IF lv_is_new_month = abap_true.
        lv_month_beghsl = ls_current-beghsl.
        lv_month_begwsl = ls_current-begwsl.
        lv_is_new_month = abap_false.
      ENDIF.

      APPEND ls_current TO lt_final_display.

      " 累加本月合计发生额
      ls_sum_month-wsl    = ls_sum_month-wsl + ls_current-wsl.
      ls_sum_month-hsl    = ls_sum_month-hsl + ls_current-hsl.
      ls_sum_month-dkfwsl = ls_sum_month-dkfwsl + ls_current-dkfwsl.
      ls_sum_month-dkfhsl = ls_sum_month-dkfhsl + ls_current-dkfhsl.

      " 累加本年累计发生额
      ls_sum_year-wsl     = ls_sum_year-wsl + ls_current-wsl.
      ls_sum_year-hsl     = ls_sum_year-hsl + ls_current-hsl.
      ls_sum_year-dkfwsl  = ls_sum_year-dkfwsl + ls_current-dkfwsl.
      ls_sum_year-dkfhsl  = ls_sum_year-dkfhsl + ls_current-dkfhsl.

      " 探查下一行状态 (利用安全的 lv_current_index)
      DATA: ls_next TYPE ts_s_alvplay.
      CLEAR ls_next.
      DATA(lv_next_idx) = lv_current_index + 1.
      READ TABLE lt_alv_display INTO ls_next INDEX lv_next_idx.
      DATA(lv_is_last_row) = sy-subrc.

      " -------------------------------------------------------------------
      " 【输出 1：本月合计】
      " -------------------------------------------------------------------
      IF lv_is_last_row <> 0 OR
         ls_next-rbukrs <> ls_current-rbukrs OR
         ls_next-lifnr  <> ls_current-lifnr  OR
         ls_next-racct  <> ls_current-racct  OR
         ls_next-rwcur  <> ls_current-rwcur  OR
         ls_next-rhcur  <> ls_current-rhcur  OR
         ls_next-gjahr  <> ls_current-gjahr  OR
         ls_next-poper  <> ls_current-poper.

*        ls_sum_month-rbukrs = ls_current-rbukrs.
*        ls_sum_month-lifnr  = ls_current-lifnr.
*        ls_sum_month-name1  = ls_current-name1.
*        ls_sum_month-gjahr  = ls_current-gjahr.
*        ls_sum_month-poper  = ls_current-poper.
*        ls_sum_month-racct  = ls_current-racct.
*        ls_sum_month-rwcur  = ls_current-rwcur.
*        ls_sum_month-rhcur  = ls_current-rhcur.
        ls_sum_month-bktxt  = '本月合计'.

        " 给本月合计上绿色 (col_positive = 5)
*        CLEAR: lt_s_color.
*        ls_s_color-fname = 'BKTXT'.
*        ls_s_color-color-col = col_positive.
*        ls_s_color-color-int = 1.
*        APPEND ls_s_color TO lt_s_color.
*        ls_sum_month-t_color = lt_s_color.
        " 👇 👇 👇 【修改这部分：让整行变绿色】 👇 👇 👇
        CLEAR: lt_s_color.
        CLEAR: ls_s_color.
        ls_s_color-fname = ''.             " <--- 关键修改：留空代表整行变色，而不是只有 BKTXT 格子
        ls_s_color-color-col = col_positive. " 绿色 (5)
        ls_s_color-color-int = 1.            " 1 代表高亮/深色，0 代表浅色
        APPEND ls_s_color TO lt_s_color.
        ls_sum_month-t_color = lt_s_color.

        " 镜像直取：毫无倒推误差
        ls_sum_month-beghsl = lv_month_beghsl.
        ls_sum_month-begwsl = lv_month_begwsl.
        ls_sum_month-endhsl = ls_current-endhsl.
        ls_sum_month-endwsl = ls_current-endwsl.

        IF ls_sum_month-endhsl > 0.
          ls_sum_month-drcrkt = '借'.
        ELSEIF ls_sum_month-endhsl < 0.
          ls_sum_month-drcrkt = '贷'.
        ELSE.
          ls_sum_month-drcrkt = '平'.
        ENDIF.

        APPEND ls_sum_month TO lt_final_display.
        CLEAR ls_sum_month.
        lv_is_new_month = abap_true. " 通知系统下个月开始抓新期初
      ENDIF.

      " -------------------------------------------------------------------
      " 【输出 2：本年累计】
      " -------------------------------------------------------------------
      IF lv_is_last_row <> 0 OR
         ls_next-rbukrs <> ls_current-rbukrs OR
         ls_next-lifnr  <> ls_current-lifnr  OR
         ls_next-racct  <> ls_current-racct  OR
         ls_next-rwcur  <> ls_current-rwcur  OR
         ls_next-rhcur  <> ls_current-rhcur  OR
         ls_next-gjahr  <> ls_current-gjahr.

*        ls_sum_year-rbukrs = ls_current-rbukrs.
*        ls_sum_year-lifnr  = ls_current-lifnr.
*        ls_sum_year-name1  = ls_current-name1.
*        ls_sum_year-gjahr  = ls_current-gjahr.
*        ls_sum_year-poper  = ls_current-poper.
*        ls_sum_year-racct  = ls_current-racct.
*        ls_sum_year-rwcur  = ls_current-rwcur.
*        ls_sum_year-rhcur  = ls_current-rhcur.
        ls_sum_year-bktxt  = '本年累计'.

        " 给本年累计上红色 (col_negative = 6)
*        CLEAR: lt_s_color.
*        ls_s_color-fname = 'BKTXT'.
*        ls_s_color-color-col = 6.
*        ls_s_color-color-int = 1.
*        APPEND ls_s_color TO lt_s_color.
*        ls_sum_year-t_color = lt_s_color.
        " 👇 👇 👇 【修改这部分：让整行变绿色】 👇 👇 👇
        CLEAR: lt_s_color.
        CLEAR: ls_s_color.
        ls_s_color-fname = ''.             " <--- 关键修改：留空代表整行变色，而不是只有 BKTXT 格子
        ls_s_color-color-col = col_positive. " 绿色 (5)
        ls_s_color-color-int = 1.            " 1 代表高亮/深色，0 代表浅色
        APPEND ls_s_color TO lt_s_color.
        ls_sum_year-t_color = lt_s_color.

        " 镜像直取：毫无倒推误差
        ls_sum_year-beghsl = lv_year_beghsl.
        ls_sum_year-begwsl = lv_year_begwsl.
        ls_sum_year-endhsl = ls_current-endhsl.
        ls_sum_year-endwsl = ls_current-endwsl.

        IF ls_sum_year-endhsl > 0.
          ls_sum_year-drcrkt = '借'.
        ELSEIF ls_sum_year-endhsl < 0.
          ls_sum_year-drcrkt = '贷'.
        ELSE.
          ls_sum_year-drcrkt = '平'.
        ENDIF.

        APPEND ls_sum_year TO lt_final_display.
        CLEAR ls_sum_year.
        lv_is_new_year = abap_true. " 通知系统下一个维度开始抓新期初
      ENDIF.

    ENDLOOP.

    lt_alv_display = lt_final_display.

  ENDMETHOD.





  METHOD write_player_show_detail_alv.

    DATA:
      lt_comps TYPE abap_compdescr_tab,
      lr_struc TYPE REF TO cl_abap_structdescr.
    FIELD-SYMBOLS:<fs_comps> LIKE LINE OF lt_comps.
    DATA:lo_salv_msg       TYPE REF TO cx_salv_msg,
         lo_salv_not_found TYPE REF TO cx_salv_not_found,
         lv_msg            TYPE string.

    lr_struc ?= cl_abap_typedescr=>describe_by_data( me->ls_alv_display ).
    lt_comps = lr_struc->components.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = gr_table
          CHANGING
            t_table      = me->lt_alv_display ).
      CATCH cx_salv_msg INTO lo_salv_msg.
        lv_msg = lo_salv_msg->get_text( ).
        MESSAGE lv_msg TYPE 'E'.
    ENDTRY.

    TRY.
        gr_columns = gr_table->get_columns( ).
        gr_columns->set_optimize( 'X' ).
        TRY.
            gr_columns->set_color_column( value = 'T_COLOR' ).
          CATCH cx_salv_data_error. " ALV: General Error Class (Checked in Syntax Check)

        ENDTRY.

        LOOP AT lt_comps ASSIGNING <fs_comps>.

          " 🚨 关键修复：如果是颜色字段，直接跳过，不要对他进行列格式化 🚨
          CHECK <fs_comps>-name <> 'T_COLOR'.
          gr_column ?= gr_columns->get_column( <fs_comps>-name ).

          CASE <fs_comps>-name.
            WHEN 'RBUKRS'. "公司代码
              gr_column->set_long_text( '公司代码' ).
              gr_column->set_medium_text( '公司代码').
              gr_column->set_short_text( '公司代码').
              gr_column->set_output_length( 15 ).
            WHEN 'LIFNR'. "供应商编码
              gr_column->set_long_text( '供应商编码' ).
              gr_column->set_medium_text( '供应商编码').
              gr_column->set_short_text( '供应商编码').
              gr_column->set_output_length( 15 ).
            WHEN 'NAME1'. "供应商名称
              gr_column->set_long_text( '供应商名称' ).
              gr_column->set_medium_text( '供应商名称').
              gr_column->set_short_text( '供应商名称').
              gr_column->set_output_length( 15 ).
            WHEN 'GORK'. "供应商还是客商
              gr_column->set_long_text( '区分客商' ).
              gr_column->set_medium_text( '区分客商').
              gr_column->set_short_text( '区分客商').
              gr_column->set_output_length( 15 ).
            WHEN 'GJAHR'. "年度
              gr_column->set_long_text( '年度' ).
              gr_column->set_medium_text( '年度').
              gr_column->set_short_text( '年度').
              gr_column->set_output_length( 15 ).
            WHEN 'POPER'. "期间
              gr_column->set_long_text( '期间' ).
              gr_column->set_medium_text( '期间').
              gr_column->set_short_text( '期间').
              gr_column->set_output_length( 15 ).
            WHEN 'RACCT'. "总账科目
              gr_column->set_long_text( '总账科目' ).
              gr_column->set_medium_text( '总账科目').
              gr_column->set_short_text( '总账科目').
              gr_column->set_output_length( 15 ).
            WHEN 'BUDAT'. "过账日期
              gr_column->set_long_text( '过账日期' ).
              gr_column->set_medium_text( '过账日期').
              gr_column->set_short_text( '过账日期').
              gr_column->set_output_length( 15 ).
            WHEN 'TXT50'. "科目描述
              gr_column->set_long_text( '科目描述' ).
              gr_column->set_medium_text( '科目描述').
              gr_column->set_short_text( '科目描述').
              gr_column->set_output_length( 15 ).
            WHEN 'BELNR'. "凭证编码
              gr_column->set_long_text( '凭证编码' ).
              gr_column->set_medium_text( '凭证编码').
              gr_column->set_short_text( '凭证编码').
              gr_column->set_output_length( 15 ).
              gr_column->set_cell_type( EXPORTING value = if_salv_c_cell_type=>hotspot ).

            WHEN 'HFC_DOC'. "凭证编码 hfc
              gr_column->set_long_text( '会计凭证编号' ).
              gr_column->set_medium_text( '会计凭证编号').
              gr_column->set_short_text( '会计凭证编号').
              gr_column->set_output_length( 15 ).

            WHEN 'BKTXT'. "摘要
              gr_column->set_long_text( '摘要' ).
              gr_column->set_medium_text( '摘要').
              gr_column->set_short_text( '摘要').
              gr_column->set_output_length( 15 ).

            WHEN 'RWCUR'. "原币
              gr_column->set_long_text( '原币货币' ).
              gr_column->set_medium_text( '原币货币').
              gr_column->set_short_text( '原币货币').
              gr_column->set_output_length( 15 ).
              IF s_waers-low = 'CNY'.
                gr_column->set_visible(
                  value = if_salv_c_bool_sap=>false
                ).
              ENDIF.
            WHEN 'RHCUR'. "本币
              gr_column->set_long_text( '本币货币' ).
              gr_column->set_medium_text( '本币货币').
              gr_column->set_short_text( '本币货币').
              gr_column->set_output_length( 15 ).

            WHEN 'WSL'. "本期原币发生金额（借方）
              gr_column->set_long_text( '本期原币发生金额（借方）' ).
              gr_column->set_medium_text( '本期原币发生金额（借方）').
              gr_column->set_short_text( '本期原币金额（借方）').
              gr_column->set_output_length( 15 ).

              IF s_waers-low = 'CNY'.
                gr_column->set_visible(
                  value = if_salv_c_bool_sap=>false
                ).
              ENDIF.

            WHEN 'HSL'. "本期本币发生金额（借方）
              gr_column->set_long_text( '本期本币发生金额（借方）' ).
              gr_column->set_medium_text( '本期本币发生金额（借方）').
              gr_column->set_short_text( '本期本币金额（借方）').
              gr_column->set_output_length( 15 ).


            WHEN 'DRCRKD'. "本期发生借贷标识
              gr_column->set_long_text( '借贷标识' ).
              gr_column->set_medium_text( '借贷标识').
              gr_column->set_short_text( '借贷标识').
              gr_column->set_output_length( 15 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).

            WHEN 'DKFWSL'. "本期原币发生金额（贷方）
              gr_column->set_long_text( '本期原币发生金额（贷方）' ).
              gr_column->set_medium_text( '本期原币发生金额（贷方）').
              gr_column->set_short_text( '本期原币金额（贷方）').
              gr_column->set_output_length( 15 ).

              IF s_waers-low = 'CNY'.
                gr_column->set_visible(
                  value = if_salv_c_bool_sap=>false
                ).
              ENDIF.

            WHEN 'DKFHSL'. "本期本币发生金额（贷方）
              gr_column->set_long_text( '本期本币发生金额（贷方）' ).
              gr_column->set_medium_text( '本期本币发生金额（贷方）').
              gr_column->set_short_text( '本期本币金额（贷方）').
              gr_column->set_output_length( 15 ).

            WHEN 'DRCRKT'. "借贷标识中文
              gr_column->set_long_text( '借贷标识中文' ).
              gr_column->set_medium_text( '借贷标识中文').
              gr_column->set_short_text( '借贷标识中文').
              gr_column->set_output_length( 15 ).

            WHEN 'EBELN'. "采购订单编码
              gr_column->set_long_text( '采购订单编码' ).
              gr_column->set_medium_text( '采购订单编码').
              gr_column->set_short_text( '采购订单编码').
              gr_column->set_output_length( 15 ).
              gr_column->set_cell_type( EXPORTING value = if_salv_c_cell_type=>hotspot ).

            WHEN 'ZZ002'. "发票号
              gr_column->set_long_text( '发票号' ).
              gr_column->set_medium_text( '发票号').
              gr_column->set_short_text( '发票号').
              gr_column->set_output_length( 15 ).

            WHEN 'BEGWSL'. "期初原币金额
              gr_column->set_long_text( '期初原币金额' ).
              gr_column->set_medium_text( '期初原币' ).
              gr_column->set_short_text( '期初原币' ).
              gr_column->set_output_length( 18 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).


            WHEN 'BEGHSL'. "期初本币金额
              gr_column->set_long_text( '期初本币金额' ).
              gr_column->set_medium_text( '期初本币' ).
              gr_column->set_short_text( '期初本币' ).
              gr_column->set_output_length( 18 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).


            WHEN 'ENDWSL'. "期末原币金额
              gr_column->set_long_text( '期末原币金额' ).
              gr_column->set_medium_text( '期末原币' ).
              gr_column->set_short_text( '期末原币' ).
              gr_column->set_output_length( 18 ).

            WHEN 'ENDHSL'. "期末本币金额
              gr_column->set_long_text( '期末本币金额' ).
              gr_column->set_medium_text( '期末本币' ).
              gr_column->set_short_text( '期末本币' ).
              gr_column->set_output_length( 18 ).


            WHEN OTHERS.

          ENDCASE.

          gr_column->set_zero(
            value = if_salv_c_bool_sap=>false
          ).
        ENDLOOP.

      CATCH cx_salv_not_found INTO lo_salv_not_found.
        lv_msg = lo_salv_not_found->get_text( ).
        MESSAGE lv_msg TYPE 'E'.
    ENDTRY.





    DATA: lr_events TYPE REF TO cl_salv_events_table.
    lr_events = gr_table->get_event( ).
    SET HANDLER me->on_hotspot_click FOR lr_events.

    gr_layout = gr_table->get_layout( ).
    gs_program-report = sy-repid.
    gr_layout->set_default( abap_true ).
    gr_layout->set_key( gs_program ).
    gr_layout->set_save_restriction( cl_salv_layout=>restrict_none ).


    DATA: lr_functions TYPE REF TO cl_salv_functions_list.
    lr_functions = gr_table->get_functions( ).
    lr_functions->set_all( abap_true ).
    gr_selection = gr_table->get_selections( ).
    gr_selection->set_selection_mode( if_salv_c_selection_mode=>none ).

    DATA(lo_display) = gr_table->get_display_settings( ).

    " 设置标题文字
    DATA: lv_header TYPE  lvc_title.
    lv_header = '客商辅助明细表' &&  p_gjahr && |年| && s_monat-low && |-| && s_monat-high && |月|.
    lo_display->set_list_header( lv_header ).

    gr_table->set_screen_status(
      pfstatus      = 'STANDARD_FULLSCREEN'
      report        = 'SAPLKKBL'
      set_functions = gr_table->c_functions_all ).

    gr_table->display( ).

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

    TRY.
        gr_columns = gr_table->get_columns( ).
        gr_columns->set_optimize( 'X' ).
        LOOP AT lt_comps ASSIGNING <fs_comps>.
          gr_column ?= gr_columns->get_column( <fs_comps>-name ).
          CASE <fs_comps>-name.
            WHEN 'RBUKRS'. "公司代码
              gr_column->set_long_text( '公司代码' ).
              gr_column->set_medium_text( '公司代码').
              gr_column->set_short_text( '公司代码').
              gr_column->set_output_length( 15 ).
            WHEN 'LIFNR'. "供应商编码
              gr_column->set_long_text( '客商编码' ).
              gr_column->set_medium_text( '客商编码').
              gr_column->set_short_text( '客商编码').
              gr_column->set_output_length( 15 ).
            WHEN 'GORK'. "供应商还是客商
              gr_column->set_long_text( '区分客商' ).
              gr_column->set_medium_text( '区分客商').
              gr_column->set_short_text( '区分客商').
              gr_column->set_output_length( 15 ).
            WHEN 'NAME1'. "供应商名称
              gr_column->set_long_text( '客商名称' ).
              gr_column->set_medium_text( '客商名称').
              gr_column->set_short_text( '客商名称').
              gr_column->set_output_length( 15 ).
            WHEN 'RACCT'. "总账科目
              gr_column->set_long_text( '总账科目' ).
              gr_column->set_medium_text( '总账科目').
              gr_column->set_short_text( '总账科目').
              gr_column->set_output_length( 15 ).
              gr_column->set_cell_type( EXPORTING value = if_salv_c_cell_type=>hotspot ).

            WHEN 'TXT50'. "科目描述
              gr_column->set_long_text( '科目描述' ).
              gr_column->set_medium_text( '科目描述').
              gr_column->set_short_text( '科目描述').
              gr_column->set_output_length( 15 ).

            WHEN 'RWCUR'. "原币
              gr_column->set_long_text( '原币货币' ).
              gr_column->set_medium_text( '原币货币').
              gr_column->set_short_text( '原币货币').
              gr_column->set_output_length( 15 ).
              IF s_waers-low = 'CNY'.
                gr_column->set_visible(
                  value = if_salv_c_bool_sap=>false
                ).
              ENDIF.
            WHEN 'RHCUR'. "本币
              gr_column->set_long_text( '本币货币' ).
              gr_column->set_medium_text( '本币货币').
              gr_column->set_short_text( '本币货币').
              gr_column->set_output_length( 15 ).

            WHEN 'QCYBED'. "期初原币金额（借方）
              gr_column->set_long_text( '期初原币金额（借方）' ).
              gr_column->set_medium_text( '期初原币金额（借方）').
              gr_column->set_short_text( '期初原币金额（借方）').
              gr_column->set_output_length( 15 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).
            WHEN 'QCBBED'. "期初本币金额（借方）
              gr_column->set_long_text( '期初本币金额（借方）' ).
              gr_column->set_medium_text( '期初本币金额（借方）').
              gr_column->set_short_text( '期初本币金额（借方）').
              gr_column->set_output_length( 15 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).

            WHEN 'DRCRK'. "期初借方标识
              gr_column->set_long_text( '期初借方标识' ).
              gr_column->set_medium_text( '期初借方标识').
              gr_column->set_short_text( '期初借方标识').
              gr_column->set_output_length( 15 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).

            WHEN 'QCDFYBED'. "期初原币金额（贷方）
              gr_column->set_long_text( '期初原币金额（贷方）' ).
              gr_column->set_medium_text( '期初原币金额（贷方）').
              gr_column->set_short_text( '期初原币金额（贷方）').
              gr_column->set_output_length( 15 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).

            WHEN 'QCDFBBED'. "期初本币金额（贷方）
              gr_column->set_long_text( '期初本币金额（贷方）' ).
              gr_column->set_medium_text( '期初本币金额（贷方）').
              gr_column->set_short_text( '期初本币金额（贷方）').
              gr_column->set_output_length( 15 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).
            WHEN 'DRDFCRK'. "期初贷方标识
              gr_column->set_long_text( '期初贷方标识' ).
              gr_column->set_medium_text( '期初贷方标识').
              gr_column->set_short_text( '期初贷方标识').
              gr_column->set_output_length( 15 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).

***            add new
            WHEN 'QCYBYENEW'. "期初原币金额（贷方）
              gr_column->set_long_text( '期初原币余额' ).
              gr_column->set_medium_text( '期初原币余额').
              gr_column->set_short_text( '期初原币余额').
              gr_column->set_output_length( 15 ).
              IF s_waers-low = 'CNY'.
                gr_column->set_visible(
                  value = if_salv_c_bool_sap=>false
                ).
              ENDIF.

            WHEN 'QCBBYENEW'. "期初本币金额（贷方）
              gr_column->set_long_text( '期初本币余额' ).
              gr_column->set_medium_text( '期初本币余额').
              gr_column->set_short_text( '期初本币余额').
              gr_column->set_output_length( 15 ).
*              gr_column->set_visible(
*                value = if_salv_c_bool_sap=>false
*              ).
            WHEN 'QCJDBIAOS'. "期初贷方标识
              gr_column->set_long_text( '期初借贷标识' ).
              gr_column->set_medium_text( '期初借贷标识').
              gr_column->set_short_text( '期初借贷标识').
              gr_column->set_output_length( 15 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).

            WHEN 'QCJDBST'. "期初借贷标识中文
              gr_column->set_long_text( '期初借贷标识' ).
              gr_column->set_medium_text( '期初借贷标识').
              gr_column->set_short_text( '期初借贷标识').
              gr_column->set_output_length( 15 ).
*              gr_column->set_visible(
*                value = if_salv_c_bool_sap=>false
*              ).
**             add new

            WHEN 'WSL'. "本期原币发生金额（借方）
              gr_column->set_long_text( '本期原币发生金额（借方）' ).
              gr_column->set_medium_text( '本期原币发生金额（借方）').
              gr_column->set_short_text( '本期原币金额（借方）').
              gr_column->set_output_length( 15 ).

              IF s_waers-low = 'CNY'.
                gr_column->set_visible(
                  value = if_salv_c_bool_sap=>false
                ).
              ENDIF.

            WHEN 'HSL'. "本期本币发生金额（借方）
              gr_column->set_long_text( '本期本币发生金额（借方）' ).
              gr_column->set_medium_text( '本期本币发生金额（借方）').
              gr_column->set_short_text( '本期本币金额（借方）').
              gr_column->set_output_length( 15 ).


            WHEN 'DRCRKD'. "本期发生借贷标识
              gr_column->set_long_text( '期末借贷标识' ).
              gr_column->set_medium_text( '期末借贷标识').
              gr_column->set_short_text( '期末借贷标识').
              gr_column->set_output_length( 15 ).
              gr_column->set_visible(
                value = if_salv_c_bool_sap=>false
              ).

            WHEN 'DRCRKT'. "
              gr_column->set_long_text( '期末借贷标识' ).
              gr_column->set_medium_text( '期末借贷标识').
              gr_column->set_short_text( '期末借贷标识').
              gr_column->set_output_length( 15 ).

            WHEN 'DKFWSL'. "本期原币发生金额（贷方）
              gr_column->set_long_text( '本期原币发生金额（贷方）' ).
              gr_column->set_medium_text( '本期原币发生金额（贷方）').
              gr_column->set_short_text( '本期原币金额（贷方）').
              gr_column->set_output_length( 15 ).

              IF s_waers-low = 'CNY'.
                gr_column->set_visible(
                  value = if_salv_c_bool_sap=>false
                ).
              ENDIF.

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
              IF s_waers-low = 'CNY'.
                gr_column->set_visible(
                  value = if_salv_c_bool_sap=>false
                ).
              ENDIF.
            WHEN 'QMBBED'. "期末本币额度
              gr_column->set_long_text( '期末本币额度' ).
              gr_column->set_medium_text( '期末本币额度').
              gr_column->set_short_text( '期末本币额度').
              gr_column->set_output_length( 15 ).

            WHEN OTHERS.

          ENDCASE.
        ENDLOOP.

      CATCH cx_salv_not_found INTO lo_salv_not_found.
        lv_msg = lo_salv_not_found->get_text( ).
        MESSAGE lv_msg TYPE 'E'.
    ENDTRY.

    DATA: lr_events TYPE REF TO cl_salv_events_table.
    lr_events = gr_table->get_event( ).
    SET HANDLER me->on_hotspot_click FOR lr_events.

    gr_layout = gr_table->get_layout( ).
    gs_program-report = sy-repid.
    gr_layout->set_default( abap_true ).
    gr_layout->set_key( gs_program ).
    gr_layout->set_save_restriction( cl_salv_layout=>restrict_none ).

    DATA: lr_functions TYPE REF TO cl_salv_functions_list.
    lr_functions = gr_table->get_functions( ).
    lr_functions->set_all( abap_true ).
    gr_selection = gr_table->get_selections( ).
    gr_selection->set_selection_mode( if_salv_c_selection_mode=>none ).

    DATA(lo_display) = gr_table->get_display_settings( ).

    " 设置标题文字
    DATA: lv_header TYPE  lvc_title.
    lv_header = '客商辅助余额表' &&  p_gjahr && |年| && s_monat-low && |-| && s_monat-high && |月|.
    lo_display->set_list_header( lv_header ).
    gr_table->set_screen_status(
      pfstatus      = 'STANDARD_FULLSCREEN'
      report        = 'SAPLKKBL'
      set_functions = gr_table->c_functions_all ).

    gr_table->display( ).


  ENDMETHOD.


  METHOD write_player_details.

    " --- 新增：定义用于追踪分组的哈希表 ---
    TYPES: tt_processed_keys TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.
    DATA: lt_processed_keys TYPE tt_processed_keys.

    " --- 定义辅助颜色结构 ---
    DATA: lt_s_color TYPE lvc_t_scol,
          ls_s_color TYPE lvc_s_scol.

    " =====================================================================
    " 1. 【核心防御】前台条件强行清洗底层脏数据 (杜绝跨币种污染)
    " =====================================================================
    IF s_waers[] IS NOT INITIAL.
      DELETE me->lt_find WHERE rwcur NOT IN s_waers.
    ENDIF.
    IF s_racct[] IS NOT INITIAL.
      DELETE me->lt_find WHERE racct NOT IN s_racct.
    ENDIF.

    TYPES: BEGIN OF ty_beg_bal,
             rbukrs TYPE acdoca-rbukrs,
             lifnr  TYPE acdoca-lifnr,
             racct  TYPE acdoca-racct,
             rwcur  TYPE acdoca-rwcur,
             rhcur  TYPE acdoca-rhcur,
             beghsl TYPE acdoca-hsl,
             begwsl TYPE acdoca-wsl,
           END OF ty_beg_bal.

    DATA: lt_beg_bal       TYPE TABLE OF ty_beg_bal,
          lt_final_display TYPE TABLE OF ts_s_alvplay,
          ls_sum_month     TYPE ts_s_alvplay,
          ls_sum_year      TYPE ts_s_alvplay.

    DATA: lv_delpoplo TYPE poper,
          lv_delpoper TYPE poper.

    READ TABLE s_monat INTO DATA(ls_monat) INDEX 1.
    IF sy-subrc = 0.
      lv_delpoplo = ls_monat-low.
      lv_delpoper = ls_monat-high.
      IF lv_delpoper IS INITIAL.
        lv_delpoper = ls_monat-low.
      ENDIF.
      IF lv_delpoper > '12'.
        lv_delpoper = '12'.
      ENDIF.
    ENDIF.

    " =====================================================================
    " 2. 极速捞取“期初余额”
    " =====================================================================
    SELECT rbukrs, lifnr, kunnr, racct, rwcur, rhcur,
           SUM( hsl ) AS beghsl,
           SUM( wsl ) AS begwsl
      FROM acdoca
     WHERE rbukrs IN @s_bukrs
       AND lifnr  IN @s_lifnr
       AND kunnr  IN @s_kunnr
       AND rwcur  IN @s_waers
       AND ( gjahr < @p_gjahr OR ( gjahr = @p_gjahr AND poper < @lv_delpoplo ) )
      " ▼ 核心邏輯修改：使用括號將兩種情況包起來
*       AND ( ( racct IN @s_racct AND racct <> '2202030100' ) OR
*           ( racct = '2202030100' AND lifnr = @space ) )
      AND racct IN @s_racct
      AND NOT ( racct = '2202030100' AND lifnr <> @space )
     GROUP BY rbukrs, lifnr, kunnr, racct, rwcur, rhcur
      INTO TABLE @DATA(lt_beg_bal_raw).

    LOOP AT lt_beg_bal_raw INTO DATA(ls_raw).
      DATA(ls_beg) = VALUE ty_beg_bal( rbukrs = ls_raw-rbukrs
                                       racct  = ls_raw-racct
                                       rwcur  = ls_raw-rwcur
                                       rhcur  = ls_raw-rhcur
                                       beghsl = ls_raw-beghsl
                                       begwsl = ls_raw-begwsl ).
      IF ls_raw-lifnr IS NOT INITIAL.
        ls_beg-lifnr = ls_raw-lifnr.
      ELSE.
        ls_beg-lifnr = ls_raw-kunnr.
      ENDIF.
      COLLECT ls_beg INTO lt_beg_bal.
    ENDLOOP.

    SORT lt_beg_bal BY rbukrs lifnr racct rwcur rhcur.

    " =====================================================================
    " 3. 准备各类基础数据
    " =====================================================================
    SELECT FROM zfit_ofn AS a
      FIELDS a~bukrs, a~hfc_doc, a~belnr, a~gjahr, a~monat
      WHERE a~bukrs IN @s_bukrs
        AND a~gjahr = @p_gjahr
      INTO TABLE @DATA(lt_zfit_ofn).
    IF sy-subrc = 0. SORT lt_zfit_ofn BY bukrs gjahr belnr. ENDIF.

    SELECT FROM lfa1 AS a
      FIELDS a~lifnr, concat( a~name1, concat( a~name2, a~name3 ) ) AS name
      ORDER BY lifnr INTO TABLE @DATA(lt_lfa1).

    SELECT FROM kna1 AS a
      FIELDS a~kunnr, concat( a~name1, a~name2 ) AS name
      ORDER BY kunnr INTO TABLE @DATA(lt_kna1).

    SELECT * FROM zc_hkont_detail_tf( iv_ktopl = '1000', iv_saknr = '0000000000', iv_spras = '1' )
      INTO TABLE @DATA(lt_skat).
    SORT lt_skat BY ktopl saknr.

    IF me->lt_findk IS NOT INITIAL. APPEND LINES OF me->lt_findk TO me->lt_find. CLEAR: me->lt_findk. ENDIF.
    IF me->lt_findbug IS NOT INITIAL. APPEND LINES OF me->lt_findbug TO me->lt_find. CLEAR: me->lt_findbug. ENDIF.

    DELETE me->lt_find WHERE lifnr = ''.
    SORT me->lt_find BY rldnr rbukrs gjahr belnr docln racct lifnr.
    DELETE ADJACENT DUPLICATES FROM me->lt_find COMPARING rldnr rbukrs gjahr belnr docln racct lifnr.

    DATA: lv_zhuanh TYPE p DECIMALS 3.
    LOOP AT me->lt_find ASSIGNING FIELD-SYMBOL(<ls_find>).
      CLEAR: lv_zhuanh.
      CALL FUNCTION 'CURRENCY_CONVERTING_FACTOR'
        EXPORTING
          currency          = <ls_find>-rwcur
        IMPORTING
          factor            = lv_zhuanh
        EXCEPTIONS
          too_many_decimals = 1
          OTHERS            = 2.
      IF sy-subrc = 0. <ls_find>-wsl = <ls_find>-wsl * lv_zhuanh. ENDIF.
      <ls_find>-rldnr = ''. <ls_find>-docln = ''.

      IF <ls_find>-lifnr IS NOT INITIAL.
        FIND FIRST OCCURRENCE OF REGEX '[一-龥]' IN <ls_find>-lifnr.
        IF sy-subrc = 0. <ls_find>-delf = abap_true. ENDIF.
      ENDIF.
    ENDLOOP.

*    DELETE me->lt_find WHERE delf = abap_true.
*    DELETE me->lt_find WHERE lifnr = ''.
*    DELETE me->lt_find WHERE gjahr <> p_gjahr.
*    DELETE me->lt_find WHERE poper > lv_delpoper.
*    DELETE me->lt_find WHERE poper < lv_delpoplo.

    DELETE me->lt_find WHERE delf = abap_true
                        OR lifnr = ''
                        OR gjahr <> p_gjahr
                        OR poper > lv_delpoper
                        OR poper < lv_delpoplo.

    SELECT FROM @me->lt_find AS a
      INNER JOIN bseg AS b ##ITAB_KEY_IN_SELECT
         ON a~rbukrs = b~bukrs AND a~gjahr  = b~gjahr AND a~belnr  = b~belnr AND a~buzei  = b~buzei
      FIELDS b~bukrs, b~belnr, b~gjahr, b~buzei, b~xnegp, b~shkzg
      INTO TABLE @DATA(lt_bsegnew).
    IF sy-subrc = 0. SORT lt_bsegnew BY bukrs belnr gjahr buzei. ENDIF.

    " =====================================================================
    " 4. 映射到展示内表
    " =====================================================================
    LOOP AT me->lt_find ASSIGNING <ls_find>.
      APPEND INITIAL LINE TO lt_alv_display ASSIGNING FIELD-SYMBOL(<ls_alv_display>).
      <ls_alv_display>-rbukrs = <ls_find>-rbukrs.
      <ls_alv_display>-lifnr  = <ls_find>-lifnr.

      READ TABLE lt_lfa1 INTO DATA(ls_lfa1) WITH KEY lifnr = <ls_find>-lifnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_alv_display>-name1 = ls_lfa1-name. <ls_alv_display>-gork  = '供应商'.
      ELSE.
        READ TABLE lt_kna1 INTO DATA(ls_kna1) WITH KEY kunnr = <ls_find>-lifnr BINARY SEARCH.
        IF sy-subrc = 0.
          <ls_alv_display>-name1 = ls_kna1-name. <ls_alv_display>-gork  = '客户'.
        ENDIF.
      ENDIF.

      <ls_alv_display>-gjahr  = <ls_find>-gjahr.
      <ls_alv_display>-poper  = <ls_find>-poper.
      <ls_alv_display>-racct  = <ls_find>-racct.
      <ls_alv_display>-budat  = <ls_find>-budat.

      READ TABLE lt_skat INTO DATA(ls_skat) WITH KEY saknr = <ls_find>-racct BINARY SEARCH.
      IF sy-subrc = 0. <ls_alv_display>-txt50 = ls_skat-txt50. ENDIF.

      <ls_alv_display>-belnr  = <ls_find>-belnr.

      READ TABLE lt_zfit_ofn INTO DATA(ls_zfit_ofn) WITH KEY bukrs = <ls_find>-rbukrs gjahr = <ls_find>-gjahr belnr = <ls_find>-belnr BINARY SEARCH.
      IF sy-subrc = 0. <ls_alv_display>-hfc_doc = ls_zfit_ofn-hfc_doc. ENDIF.

      <ls_alv_display>-bktxt  = <ls_find>-bktxt.
      <ls_alv_display>-rwcur  = <ls_find>-rwcur.
      <ls_alv_display>-rhcur  = <ls_find>-rhcur.

      READ TABLE lt_bsegnew INTO DATA(ls_bsegnew) WITH KEY bukrs = <ls_find>-rbukrs gjahr = <ls_find>-gjahr belnr = <ls_find>-belnr buzei = <ls_find>-buzei BINARY SEARCH.
      IF sy-subrc = 0.
        IF ls_bsegnew-xnegp = 'X'.
          IF ls_bsegnew-shkzg = 'S'.
            <ls_alv_display>-dkfwsl = <ls_find>-wsl. <ls_alv_display>-dkfhsl = <ls_find>-hsl.
          ELSEIF ls_bsegnew-shkzg = 'H'.
            <ls_alv_display>-wsl    = <ls_find>-wsl. <ls_alv_display>-hsl    = <ls_find>-hsl.
          ENDIF.
        ELSE.
          IF <ls_find>-hsl >= 0.
            <ls_alv_display>-wsl    = <ls_find>-wsl. <ls_alv_display>-hsl    = <ls_find>-hsl.
          ELSE.
            <ls_alv_display>-dkfwsl = <ls_find>-wsl. <ls_alv_display>-dkfhsl = <ls_find>-hsl.
          ENDIF.
        ENDIF.
      ELSE.
        IF <ls_find>-hsl >= 0.
          <ls_alv_display>-wsl    = <ls_find>-wsl. <ls_alv_display>-hsl    = <ls_find>-hsl.
        ELSE.
          <ls_alv_display>-dkfwsl = <ls_find>-wsl. <ls_alv_display>-dkfhsl = <ls_find>-hsl.
        ENDIF.
      ENDIF.
      <ls_alv_display>-drcrkd = <ls_find>-drcrk.
    ENDLOOP.

    " =====================================================================
    " 5. 【严控排序与独立账本滚算】
    " =====================================================================
    SORT lt_alv_display BY rbukrs ASCENDING
                           lifnr  ASCENDING
                           racct  ASCENDING
                           rwcur  ASCENDING
                           rhcur  ASCENDING
                           gjahr  ASCENDING
                           poper  ASCENDING.

    TYPES: BEGIN OF ty_run_bal,
             key    TYPE string,
             beghsl TYPE fins_vhcur12,
             begwsl TYPE fins_vwcur12,
           END OF ty_run_bal.
    DATA: lt_run_bal   TYPE HASHED TABLE OF ty_run_bal WITH UNIQUE KEY key,
          lv_curr_key  TYPE string,
          ls_beg_match TYPE ty_beg_bal.

    LOOP AT lt_alv_display ASSIGNING FIELD-SYMBOL(<ls_calc>).
      lv_curr_key = |{ <ls_calc>-rbukrs }-{ <ls_calc>-lifnr }-{ <ls_calc>-racct }-{ <ls_calc>-rwcur }-{ <ls_calc>-rhcur }|.

      READ TABLE lt_run_bal ASSIGNING FIELD-SYMBOL(<ls_run_bal>) WITH TABLE KEY key = lv_curr_key.
      IF sy-subrc <> 0.
        DATA(ls_new_bal) = VALUE ty_run_bal( key = lv_curr_key ).
        READ TABLE lt_beg_bal INTO ls_beg_match
             WITH KEY rbukrs = <ls_calc>-rbukrs
                      lifnr  = <ls_calc>-lifnr
                      racct  = <ls_calc>-racct
                      rwcur  = <ls_calc>-rwcur
                      rhcur  = <ls_calc>-rhcur BINARY SEARCH.
        IF sy-subrc = 0.
          ls_new_bal-beghsl = ls_beg_match-beghsl.
          ls_new_bal-begwsl = ls_beg_match-begwsl.
        ENDIF.
        INSERT ls_new_bal INTO TABLE lt_run_bal ASSIGNING <ls_run_bal>.
      ENDIF.

      <ls_calc>-beghsl = <ls_run_bal>-beghsl.
      <ls_calc>-begwsl = <ls_run_bal>-begwsl.

      <ls_calc>-endhsl = <ls_calc>-beghsl + <ls_calc>-hsl - <ls_calc>-dkfhsl.
      <ls_calc>-endwsl = <ls_calc>-begwsl + <ls_calc>-wsl - <ls_calc>-dkfwsl.

      IF <ls_calc>-endhsl > 0.
        <ls_calc>-drcrkt = '借'.
      ELSEIF <ls_calc>-endhsl < 0.
        <ls_calc>-drcrkt = '贷'.
      ELSE.
        <ls_calc>-drcrkt = '平'.
      ENDIF.

      <ls_run_bal>-beghsl = <ls_calc>-endhsl.
      <ls_run_bal>-begwsl = <ls_calc>-endwsl.
    ENDLOOP.

    " =====================================================================
    " 6. 【终极修复】镜像追踪法：彻底告别计算偏差与串行
    " =====================================================================
    CLEAR lt_final_display.
    CLEAR: ls_sum_month, ls_sum_year.

    DATA: lv_is_new_month TYPE abap_bool VALUE abap_true,
          lv_is_new_year  TYPE abap_bool VALUE abap_true.

    DATA: lv_month_beghsl TYPE fins_vhcur12,
          lv_month_begwsl TYPE fins_vwcur12,
          lv_year_beghsl  TYPE fins_vhcur12,
          lv_year_begwsl  TYPE fins_vwcur12.

    LOOP AT lt_alv_display INTO DATA(ls_current).

      " ！！！【核心修复】！！！
      " 必须在进入循环的第一步立刻抓取 sy-tabix。
      " 因为后面的 INSERT 会把 sy-tabix 刷成 0，导致下一行判断错乱。
      DATA(lv_current_index) = sy-tabix.

      " --- 新增：插入期初余额的逻辑 ---
      DATA(lv_group_key) = |{ ls_current-rbukrs }-{ ls_current-lifnr }-{ ls_current-racct }-{ ls_current-rwcur }-{ ls_current-gjahr }-{ ls_current-poper }|.

      IF NOT line_exists( lt_processed_keys[ table_line = lv_group_key ] ).
        " 1. 构造期初行
        DATA: ls_opening TYPE ts_s_alvplay.
        ls_opening-bktxt = '期初余额'.
        ls_opening-endhsl = ls_current-beghsl.
        ls_opening-endwsl = ls_current-begwsl.

        " 设置期初余额的借贷方向
        IF ls_opening-endhsl > 0.
          ls_opening-drcrkt = '借'.
        ELSEIF ls_opening-endhsl < 0.
          ls_opening-drcrkt = '贷'.
        ELSE.
          ls_opening-drcrkt = '平'.
        ENDIF.

        " 2. 插入到最终输出表
        APPEND ls_opening TO lt_final_display.

        " 3. 标记该分组已插入
        INSERT lv_group_key INTO TABLE lt_processed_keys.
      ENDIF.
      " ---------------------------------

      " --- 绝对准确的期初抓取：只抓每一段跳变的【第一行】的期初 ---
      IF lv_is_new_year = abap_true.
        lv_year_beghsl = ls_current-beghsl.
        lv_year_begwsl = ls_current-begwsl.
        lv_is_new_year = abap_false.
      ENDIF.

      IF lv_is_new_month = abap_true.
        lv_month_beghsl = ls_current-beghsl.
        lv_month_begwsl = ls_current-begwsl.
        lv_is_new_month = abap_false.
      ENDIF.

      APPEND ls_current TO lt_final_display.

      " 累加本月合计发生额
      ls_sum_month-wsl    = ls_sum_month-wsl + ls_current-wsl.
      ls_sum_month-hsl    = ls_sum_month-hsl + ls_current-hsl.
      ls_sum_month-dkfwsl = ls_sum_month-dkfwsl + ls_current-dkfwsl.
      ls_sum_month-dkfhsl = ls_sum_month-dkfhsl + ls_current-dkfhsl.

      " 累加本年累计发生额
      ls_sum_year-wsl     = ls_sum_year-wsl + ls_current-wsl.
      ls_sum_year-hsl     = ls_sum_year-hsl + ls_current-hsl.
      ls_sum_year-dkfwsl  = ls_sum_year-dkfwsl + ls_current-dkfwsl.
      ls_sum_year-dkfhsl  = ls_sum_year-dkfhsl + ls_current-dkfhsl.

      " 探查下一行状态 (利用安全的 lv_current_index)
      DATA: ls_next TYPE ts_s_alvplay.
      CLEAR ls_next.
      DATA(lv_next_idx) = lv_current_index + 1.
      READ TABLE lt_alv_display INTO ls_next INDEX lv_next_idx.
      DATA(lv_is_last_row) = sy-subrc.

      " -------------------------------------------------------------------
      " 【输出 1：本月合计】
      " -------------------------------------------------------------------
      IF lv_is_last_row <> 0 OR
         ls_next-rbukrs <> ls_current-rbukrs OR
         ls_next-lifnr  <> ls_current-lifnr  OR
         ls_next-racct  <> ls_current-racct  OR
         ls_next-rwcur  <> ls_current-rwcur  OR
         ls_next-rhcur  <> ls_current-rhcur  OR
         ls_next-gjahr  <> ls_current-gjahr  OR
         ls_next-poper  <> ls_current-poper.

*        ls_sum_month-rbukrs = ls_current-rbukrs.
*        ls_sum_month-lifnr  = ls_current-lifnr.
*        ls_sum_month-name1  = ls_current-name1.
*        ls_sum_month-gjahr  = ls_current-gjahr.
*        ls_sum_month-poper  = ls_current-poper.
*        ls_sum_month-racct  = ls_current-racct.
*        ls_sum_month-rwcur  = ls_current-rwcur.
*        ls_sum_month-rhcur  = ls_current-rhcur.
        ls_sum_month-bktxt  = '本月合计'.

        " 给本月合计上绿色 (col_positive = 5)
*        CLEAR: lt_s_color.
*        ls_s_color-fname = 'BKTXT'.
*        ls_s_color-color-col = col_positive.
*        ls_s_color-color-int = 1.
*        APPEND ls_s_color TO lt_s_color.
*        ls_sum_month-t_color = lt_s_color.
        " 👇 👇 👇 【修改这部分：让整行变绿色】 👇 👇 👇
        CLEAR: lt_s_color.
        CLEAR: ls_s_color.
        ls_s_color-fname = ''.             " <--- 关键修改：留空代表整行变色，而不是只有 BKTXT 格子
        ls_s_color-color-col = col_positive. " 绿色 (5)
        ls_s_color-color-int = 1.            " 1 代表高亮/深色，0 代表浅色
        APPEND ls_s_color TO lt_s_color.
        ls_sum_month-t_color = lt_s_color.

        " 镜像直取：毫无倒推误差
        ls_sum_month-beghsl = lv_month_beghsl.
        ls_sum_month-begwsl = lv_month_begwsl.
        ls_sum_month-endhsl = ls_current-endhsl.
        ls_sum_month-endwsl = ls_current-endwsl.

        IF ls_sum_month-endhsl > 0.
          ls_sum_month-drcrkt = '借'.
        ELSEIF ls_sum_month-endhsl < 0.
          ls_sum_month-drcrkt = '贷'.
        ELSE.
          ls_sum_month-drcrkt = '平'.
        ENDIF.

        APPEND ls_sum_month TO lt_final_display.
        CLEAR ls_sum_month.
        lv_is_new_month = abap_true. " 通知系统下个月开始抓新期初
      ENDIF.

      " -------------------------------------------------------------------
      " 【输出 2：本年累计】
      " -------------------------------------------------------------------
      IF lv_is_last_row <> 0 OR
         ls_next-rbukrs <> ls_current-rbukrs OR
         ls_next-lifnr  <> ls_current-lifnr  OR
         ls_next-racct  <> ls_current-racct  OR
         ls_next-rwcur  <> ls_current-rwcur  OR
         ls_next-rhcur  <> ls_current-rhcur  OR
         ls_next-gjahr  <> ls_current-gjahr.

*        ls_sum_year-rbukrs = ls_current-rbukrs.
*        ls_sum_year-lifnr  = ls_current-lifnr.
*        ls_sum_year-name1  = ls_current-name1.
*        ls_sum_year-gjahr  = ls_current-gjahr.
*        ls_sum_year-poper  = ls_current-poper.
*        ls_sum_year-racct  = ls_current-racct.
*        ls_sum_year-rwcur  = ls_current-rwcur.
*        ls_sum_year-rhcur  = ls_current-rhcur.
        ls_sum_year-bktxt  = '本年累计'.

        " 给本年累计上红色 (col_negative = 6)
*        CLEAR: lt_s_color.
*        ls_s_color-fname = 'BKTXT'.
*        ls_s_color-color-col = 6.
*        ls_s_color-color-int = 1.
*        APPEND ls_s_color TO lt_s_color.
*        ls_sum_year-t_color = lt_s_color.
        " 👇 👇 👇 【修改这部分：让整行变绿色】 👇 👇 👇
        CLEAR: lt_s_color.
        CLEAR: ls_s_color.
        ls_s_color-fname = ''.             " <--- 关键修改：留空代表整行变色，而不是只有 BKTXT 格子
        ls_s_color-color-col = col_positive. " 绿色 (5)
        ls_s_color-color-int = 1.            " 1 代表高亮/深色，0 代表浅色
        APPEND ls_s_color TO lt_s_color.
        ls_sum_year-t_color = lt_s_color.

        " 镜像直取：毫无倒推误差
        ls_sum_year-beghsl = lv_year_beghsl.
        ls_sum_year-begwsl = lv_year_begwsl.
        ls_sum_year-endhsl = ls_current-endhsl.
        ls_sum_year-endwsl = ls_current-endwsl.

        IF ls_sum_year-endhsl > 0.
          ls_sum_year-drcrkt = '借'.
        ELSEIF ls_sum_year-endhsl < 0.
          ls_sum_year-drcrkt = '贷'.
        ELSE.
          ls_sum_year-drcrkt = '平'.
        ENDIF.

        APPEND ls_sum_year TO lt_final_display.
        CLEAR ls_sum_year.
        lv_is_new_year = abap_true. " 通知系统下一个维度开始抓新期初
      ENDIF.

    ENDLOOP.

    lt_alv_display = lt_final_display.

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

    DELETE me->lt_find WHERE lifnr = ''.

    SORT me->lt_find BY rldnr rbukrs gjahr belnr docln racct lifnr.
    DELETE ADJACENT DUPLICATES FROM me->lt_find COMPARING rldnr rbukrs gjahr belnr docln racct lifnr.

* 启用cds 捞取 科目描述 begin
    SELECT * FROM zc_hkont_detail_tf( iv_ktopl = '1000',
                                      iv_saknr = '0000000000',
                                      iv_spras = '1' )
    INTO TABLE @DATA(lt_skat).
    SORT lt_skat BY ktopl saknr.
* 启用cds 捞取 科目描述 end

    IF s_monat-high IS NOT INITIAL.
      lv_dotime = s_monat-high - s_monat-low + 1.
    ELSE.
      lv_dotime = s_monat-low.
    ENDIF.

    DATA:lt_new_find TYPE tt_find.

    READ TABLE me->lt_poper INTO DATA(s_poper) INDEX 1.
    IF s_poper-high IS NOT INITIAL.
*      me->lv_where =  | poper <= '{ s_poper-high }' | &&
*          |and gjahr <= '{ p_gjahr }' | .
      DATA(lv_delpoper) = s_poper-high.
      DATA(lv_delpoplo) = s_poper-low.

      IF s_poper-high > '12'.
        lv_delpoper = '12'.
      ENDIF.
    ELSE.
*      me->lv_where =  | poper <= '{ s_poper-low }' |  &&
*          |and gjahr <= '{ p_gjahr }' | .
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

*    DELETE me->lt_find WHERE delf = abap_true.
*    DELETE me->lt_find WHERE lifnr = ''.

    DELETE me->lt_find WHERE delf = abap_true
                          OR lifnr = ''.
    APPEND LINES OF me->lt_find TO lt_new_find.

    DELETE lt_new_find WHERE gjahr <> p_gjahr
                          OR poper > lv_delpoper
                          OR poper < lv_delpoplo
                          OR racct NOT IN s_racct.


*    DELETE lt_new_find WHERE gjahr <> p_gjahr.
*    DELETE lt_new_find WHERE poper > lv_delpoper.
*    DELETE lt_new_find WHERE poper < lv_delpoplo.
*    DELETE lt_new_find WHERE racct NOT IN s_racct.  "增加这个科目排除
*    delete lt_new_find

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
      a~lifnr,
      a~racct,
      a~rwcur,
      a~rhcur
      WHERE a~gjahr <= @p_gjahr
      GROUP BY a~rbukrs, a~lifnr, a~racct, a~rwcur, a~rhcur
      ORDER BY a~rbukrs, a~lifnr, a~racct, a~rwcur, a~rhcur
      INTO TABLE @DATA(lt_order).

    LOOP AT lt_order INTO DATA(ls_order).
      ls_view_input-budat  = lv_datum.
      ls_view_input-gjahr  = p_gjahr.
      ls_view_input-lifnr  = ls_order-lifnr.
      ls_view_input-poper  = s_monat-low.
      ls_view_input-racct  = ls_order-racct.
      ls_view_input-rbukrs = ls_order-rbukrs.
      ls_view_input-rwcur  = ls_order-rwcur. "原币
      ls_view_input-rhcur  = ls_order-rhcur. "人民币
      COLLECT ls_view_input INTO lt_view_input.
      CLEAR:ls_view_input.
    ENDLOOP.

    IF s_waers-low = '*'. "如果选择屏幕不是人民币
    ELSE.
      DELETE lt_view_input WHERE rwcur <> s_waers-low.
    ENDIF.

    DATA:lt_parallel_sum TYPE tt_find.
    DATA:ls_find_col TYPE ts_s_find.
    LOOP AT lt_view_input INTO ls_view_input.
      LOOP AT lt_find ASSIGNING <ls_find> WHERE  rbukrs = ls_view_input-rbukrs
                                            AND  lifnr  = ls_view_input-lifnr
                                            AND  racct  = ls_view_input-racct
                                            AND  budat  <= ls_view_input-budat
                                            AND  rwcur  = ls_view_input-rwcur
                                            AND  rhcur  = ls_view_input-rhcur.
        ls_find_col-rbukrs = <ls_find>-rbukrs.
        ls_find_col-lifnr = <ls_find>-lifnr.
*        ls_find_col-gjahr = <ls_find>-gjahr.
        ls_find_col-poper = ls_view_input-poper.
        ls_find_col-racct = <ls_find>-racct.
*        ls_find_col-drcrk = is_input-drcrk.
        ls_find_col-rwcur = <ls_find>-rwcur.
        ls_find_col-rhcur = <ls_find>-rhcur.
        ls_find_col-wsl   = <ls_find>-wsl.


        ls_find_col-hsl   = <ls_find>-hsl.
        COLLECT ls_find_col INTO lt_parallel_sum.
        CLEAR:ls_find_col.                                                     .
      ENDLOOP.

    ENDLOOP.


*    CLEAR:lt_find.
*    REFRESH:lt_find.



    SORT lt_parallel_sum BY rbukrs lifnr gjahr poper racct rwcur rhcur . "这个不变

    SORT lt_new_find BY rbukrs lifnr gjahr poper racct budat.
    CLEAR: me->lt_alv_sum.

    LOOP AT lt_view_input INTO ls_view_input.

      APPEND INITIAL LINE TO me->lt_alv_sum ASSIGNING FIELD-SYMBOL(<ls_alv_sum>).
      <ls_alv_sum>-rbukrs = ls_view_input-rbukrs. "公司代码
      <ls_alv_sum>-lifnr  = ls_view_input-lifnr.   "供应商

      READ TABLE lt_lfa1 INTO DATA(ls_lfa1) WITH KEY lifnr = ls_view_input-lifnr BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_alv_sum>-name1 = ls_lfa1-name.   "供应商的名字
        <ls_alv_sum>-gork = '供应商'.
      ELSE.
        READ TABLE lt_kna1 INTO DATA(ls_kna1) WITH KEY kunnr = ls_view_input-lifnr BINARY SEARCH.
        IF sy-subrc = 0.
          <ls_alv_sum>-name1 = ls_kna1-name.
          <ls_alv_sum>-gork = '客户'.
        ENDIF.
      ENDIF.

      <ls_alv_sum>-racct  = ls_view_input-racct.

      READ TABLE lt_skat INTO DATA(ls_skat) WITH KEY saknr = <ls_alv_sum>-racct
                                           BINARY SEARCH.
      IF sy-subrc = 0.
        <ls_alv_sum>-txt50 = ls_skat-txt50.
      ENDIF.


      <ls_alv_sum>-rwcur = ls_view_input-rwcur.
      <ls_alv_sum>-rhcur = ls_view_input-rhcur.

      READ TABLE lt_parallel_sum INTO DATA(ls_parallel_sum) WITH KEY  rbukrs = ls_view_input-rbukrs
                                                            lifnr  = ls_view_input-lifnr
                                                            racct  = ls_view_input-racct
                                                            rwcur  = ls_view_input-rwcur
                                                            rhcur  = ls_view_input-rhcur.
      IF sy-subrc = 0.
        IF ls_parallel_sum-hsl >= 0.
          <ls_alv_sum>-qcybed = ls_parallel_sum-wsl.   " 期初原币额度
          <ls_alv_sum>-qcbbed = ls_parallel_sum-hsl."期初本币额度
          <ls_alv_sum>-drcrk = 'S'.
        ELSE.
          <ls_alv_sum>-qcdfybed = ls_parallel_sum-wsl."期初贷方原币额度
          <ls_alv_sum>-qcdfbbed = ls_parallel_sum-hsl."期初贷方本币额度
          <ls_alv_sum>-drdfcrk = 'H'.
        ENDIF.

        IF <ls_alv_sum>-drcrk IS INITIAL.
          <ls_alv_sum>-drcrk = 'S'.
        ENDIF.

*      期初原币余额 = 期初原币额度   借方期初               +   期初原币额度   贷方期初
        <ls_alv_sum>-qcybyenew  = <ls_alv_sum>-qcybed + <ls_alv_sum>-qcdfybed.

*      期初本币余额 = 期初本币额度   借方期初               +   期初本币额度   贷方期初
        <ls_alv_sum>-qcbbyenew  =  <ls_alv_sum>-qcbbed + <ls_alv_sum>-qcdfbbed.

        IF <ls_alv_sum>-qcbbyenew >= 0.       "期初借贷标识
          <ls_alv_sum>-qcjdbiaos = 'S'.
        ELSE.
          <ls_alv_sum>-qcjdbiaos = 'H'.
        ENDIF.

        IF <ls_alv_sum>-qcbbyenew > 0.
          <ls_alv_sum>-qcjdbst = '借'.
        ELSEIF <ls_alv_sum>-qcbbyenew = 0.
          <ls_alv_sum>-qcjdbst = '平'.
        ELSE.
          <ls_alv_sum>-qcjdbst = '贷'.
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
                                                    AND  lifnr  = ls_view_input-lifnr
                                                    AND  racct  = ls_view_input-racct
                                                    AND  rwcur  = ls_view_input-rwcur
                                                    AND  rhcur  = ls_view_input-rhcur.
        READ TABLE lt_bsegnew INTO DATA(ls_bsegnew) WITH KEY
        bukrs = ls_new_find-rbukrs
        gjahr = ls_new_find-gjahr
        belnr = ls_new_find-belnr
        buzei = ls_new_find-buzei
        BINARY SEARCH.                                      "mod-0001
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
        <ls_alv_sum>-drcrkd = 'S'.
        <ls_alv_sum>-drcrkt = '借'.
      ELSEIF <ls_alv_sum>-qmybed < 0..
        <ls_alv_sum>-drcrkd = 'H'.
        <ls_alv_sum>-drcrkt = '贷'.
      ELSEIF <ls_alv_sum>-qmybed = 0.
        <ls_alv_sum>-drcrkt = '平'.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.




  METHOD display_list_of_players.
    DATA:temp_player TYPE REF TO player.

    LOOP AT players_list INTO temp_player.
      IF temp_player IS BOUND.
        IF temp_player->lv_condition = 'P1'.
          temp_player->write_player_details( ) .
          temp_player->write_player_show_detail_alv( it_alv = lt_alv_display ).
        ELSEIF temp_player->lv_condition = 'P2'.
          temp_player->write_player_detailssum( ) .
          temp_player->write_player_show_sum_alv( it_alv = lt_alv_sum ).
        ENDIF.
        FREE temp_player.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD on_hotspot_click.



    SELECT FROM zfit_ofn AS a
      FIELDS
      a~bukrs,
      a~hfc_doc,
      a~belnr,
      a~gjahr,
      a~monat
      WHERE a~bukrs IN @s_bukrs
        AND a~gjahr = @p_gjahr
      INTO TABLE @DATA(lt_zfit_ofn).
    IF sy-subrc = 0.
      SORT lt_zfit_ofn BY bukrs gjahr belnr.
    ENDIF.


    READ TABLE me->lt_poper INTO DATA(s_poper) INDEX 1.
    IF s_poper-high IS NOT INITIAL.

      DATA(lv_delpoper) = s_poper-high.
      DATA(lv_delpoplo) = s_poper-low.

      IF s_poper-high > '12'.
        lv_delpoper = '12'.
      ENDIF.
    ELSE.
*      me->lv_where =  | poper <= '{ s_poper-low }' |  &&
*          |and gjahr <= '{ p_gjahr }' | .
      lv_delpoper = s_poper-low.
    ENDIF.
    DATA:lt_new_find TYPE tt_find.

    IF p1 = 'X'.
      READ TABLE me->lt_alv_display  INDEX row ASSIGNING FIELD-SYMBOL(<fs_data1>).
      IF sy-subrc = 0.
        CASE column.
          WHEN 'BELNR'.
            IF <fs_data1>-belnr IS NOT INITIAL.
              zcl_bc_util_jump=>fb03(
                EXPORTING
                  belnr = <fs_data1>-belnr
                  bukrs = <fs_data1>-rbukrs
                  gjahr = <fs_data1>-gjahr
              ).
            ENDIF.
          WHEN 'EBELN'.
            IF <fs_data1>-belnr IS NOT INITIAL.
              zcl_bc_util_jump=>me23n( ebeln = <fs_data1>-belnr ).
            ENDIF.
          WHEN OTHERS.
        ENDCASE.
      ENDIF.

    ELSEIF p2 = 'X'.

      READ TABLE me->lt_alv_sum  INDEX row ASSIGNING FIELD-SYMBOL(<fs_data2>).
      IF sy-subrc = 0.
        CASE column.
          WHEN 'RACCT'.

            CLEAR: lt_new_find.
            APPEND LINES OF me->lt_find TO lt_new_find.
            DELETE lt_new_find WHERE gjahr <> p_gjahr
                                  OR poper > lv_delpoper
                                  OR poper < lv_delpoplo
                                  OR racct <> <fs_data2>-racct
                                  OR lifnr <> <fs_data2>-lifnr
                                  OR rbukrs <> <fs_data2>-rbukrs
                                  OR rwcur <> <fs_data2>-rwcur
                                  OR rhcur <> <fs_data2>-rhcur .

*            新造了一个方法 把数据丢到新造的方法里面让他再执行一次 明细表的数据
            CALL METHOD me->write_player_details_new
              EXPORTING
                it_find_new = lt_new_find.


            CALL METHOD me->write_player_show_detail_alv
              EXPORTING
                it_alv = lt_alv_display.
        ENDCASE.
      ENDIF.

      READ TABLE me->lt_alv_display  INDEX row ASSIGNING <fs_data1>.
      IF sy-subrc = 0.
        CASE column.
          WHEN 'BELNR'.
            IF <fs_data1>-belnr IS NOT INITIAL.
              zcl_bc_util_jump=>fb03(
                EXPORTING
                  belnr = <fs_data1>-belnr
                  bukrs = <fs_data1>-rbukrs
                  gjahr = <fs_data1>-gjahr
              ).
            ENDIF.
          WHEN 'EBELN'.
            IF <fs_data1>-belnr IS NOT INITIAL.
              zcl_bc_util_jump=>me23n( ebeln = <fs_data1>-belnr ).
            ENDIF.
          WHEN OTHERS.
        ENDCASE.
      ENDIF.

    ENDIF.

  ENDMETHOD.



ENDCLASS.
