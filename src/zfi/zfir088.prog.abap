*&---------------------------------------------------------------------*
*& Report ZFIR088
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*********request*********user*****date********      MOdify *********
*HSDK906994           alexxiao     20260420          MOD-0001
REPORT zfir088.


TABLES:acdoca,
       bseg,
       lfa1,
       rfsdo,
       tcurc,
       lfb1.

SELECTION-SCREEN BEGIN OF BLOCK kd_0 WITH FRAME TITLE TEXT-000.
  SELECT-OPTIONS: s_kunnr FOR acdoca-kunnr MODIF ID bl1.
  SELECT-OPTIONS: s_lifnr FOR lfa1-lifnr MATCHCODE OBJECT kred MODIF ID bl2.
  SELECT-OPTIONS: s_bukrs FOR lfb1-bukrs OBLIGATORY.
  SELECT-OPTIONS: s_monat FOR bseg-h_monat NO-EXTENSION OBLIGATORY.
  PARAMETERS:p_gjahr   TYPE acdoca-gjahr OBLIGATORY.
  SELECT-OPTIONS: s_racct FOR acdoca-racct  NO INTERVALS OBLIGATORY .
  SELECT-OPTIONS:s_waers FOR tcurc-waers NO-EXTENSION NO INTERVALS OBLIGATORY  .
SELECTION-SCREEN END OF BLOCK kd_0.

*MOD-0001 begin
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: r_btn1 RADIOBUTTON GROUP grp2 DEFAULT 'X' USER-COMMAND flag.
    SELECTION-SCREEN COMMENT 3(10) TEXT-003. " 这里的 3(10) 指从第3位开始，长度10，用于显示描述文本

    " 定义第二个按钮
    PARAMETERS: r_btn2 RADIOBUTTON GROUP grp2.
    SELECTION-SCREEN COMMENT 20(10) TEXT-004. " 客户

    " 定义第三个按钮
    PARAMETERS: r_btn3 RADIOBUTTON GROUP grp2." 供应商
    SELECTION-SCREEN COMMENT 40(10) TEXT-005.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.
*MOD-0001 end

SELECTION-SCREEN BEGIN OF BLOCK bk2 WITH FRAME TITLE TEXT-002.
  PARAMETERS:p1 RADIOBUTTON GROUP gp1 DEFAULT 'X',
             p2 RADIOBUTTON GROUP gp1.
SELECTION-SCREEN END OF BLOCK bk2.


INCLUDE zfir088_lcl.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF r_btn1 = 'X' .
      IF screen-group1 = 'BL1' OR screen-group1 = 'BL2'.
        screen-active = '1'.
        MODIFY SCREEN.
      ENDIF.
    ELSEIF r_btn2 = 'X'.
      IF screen-group1 = 'BL1'.
        screen-active = '1'.
      ELSEIF screen-group1 = 'BL2'.
        screen-active = '0'.
      ENDIF.
      MODIFY SCREEN.
    ELSEIF r_btn3 = 'X'.
      IF screen-group1 = 'BL1'.
        screen-active = '0'.
      ELSEIF screen-group1 = 'BL2'.
        screen-active = '1'.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.


INITIALIZATION.
  p_gjahr = sy-datum+0(4).

  s_monat[] = VALUE #( BASE s_monat[] ( sign = 'I' option = 'EQ' low = '01' high = '12' ) ).
  s_bukrs[] = VALUE #( BASE s_bukrs[] ( sign = 'I' option = 'EQ' low = '1100' ) ).
  s_waers[] = VALUE #( BASE s_waers[] ( sign = 'I' option = 'EQ' low = '*' ) ).
  s_racct[] = VALUE #( BASE s_racct[] ( sign = 'I' option = 'CP' low = '1123*' ) ).




START-OF-SELECTION.
  DATA : player1 TYPE REF TO player.
  DATA : player2 TYPE REF TO player.

  CASE 'X'.
    WHEN p1.
      TRY.
          CREATE OBJECT player1
            EXPORTING
              iv_tbname    = 'ACDOCA'
              iv_condition = 'P1'.
        CATCH cx_my_exception.
          IF sy-msgid IS NOT INITIAL.
            " 使用来自构造方法的系统消息变量，以 E (错误) 的形式弹窗或展示
            MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                    DISPLAY LIKE 'E'.
          ELSE.
            " 兜底保护：万一系统变量漏了，报一个通用错误
            MESSAGE '创建对象失败，程序终止。' TYPE 'S' DISPLAY LIKE 'E'.
          ENDIF.

          " 彻底退出当前选择屏幕/报表事件，不再向下执行
          EXIT.
      ENDTRY.
      player=>display_list_of_players( ) .
    WHEN p2.
      TRY.
          CREATE OBJECT player2 ##EXCP_UNHANDLED
            EXPORTING
              iv_tbname    = 'ACDOCA'
              iv_condition = 'P2'.
        CATCH cx_my_exception.
      ENDTRY.
      player=>display_list_of_players( ) .
    WHEN OTHERS.
  ENDCASE.

END-OF-SELECTION.
