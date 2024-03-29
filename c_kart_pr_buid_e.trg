CREATE OR REPLACE TRIGGER SCOTT.c_kart_pr_buid_e
  before update or insert or delete on c_kart_pr
  for each row
declare
  aud_text_ log_actions.text%type;
  txt_      c_status_pr.name%type;
  txt2_     c_status_pr.name%type;
  lsk_      c_kart_pr.lsk%type;
  l_relat_cnt number;
  l_new_relat_id number;
  l_old_relat_id number;
begin
  --���� ����� ����������������
  --flag_kv_                := 0;
  c_charges.chng_relat_id := 0;

  aud_text_ := '';

  l_new_relat_id:=0;
  l_old_relat_id:=0;
  if inserting then
    --��� �������� ���-�� ����������� � �������� c_kart_pr_auid
    c_charges.tab_lsk.extend;
    c_charges.tab_lsk(c_charges.tab_lsk.last) := :new.lsk;

    :new.k_fam := initcap(:new.k_fam);
    :new.k_im  := initcap(:new.k_im);
    :new.k_ot  := initcap(:new.k_ot);
    :new.fio   := :new.k_fam || ' ' || :new.k_im || ' ' || :new.k_ot;
    if :new.id is null then
      select scott.kart_pr_id.nextval into :new.id from dual;
    end if;

    --���������� ������� ������������, ��� ����������� ��������� � ���������
    c_charges.tab_c_kart_pr_id.extend;
    c_charges.tab_c_kart_pr_id(c_charges.tab_c_kart_pr_id.last) := :new.id;

    --�� ��������� ������ - ��������� �����.
    if :new.status is null then
      :new.status := 1;
    end if;
    c_charges.nabor_lsk_ := :new.lsk;
    aud_text_            := '�������� ����� �����������: ' ||
                            trim(:new.fio);
    lsk_                 := :new.lsk;

    -- �������� ��� ������������ � kart, � �������� c_kart_pr_auid
    --if nvl(:new.relat_id, 0) = 11 then
    --  flag_kv_ := 1;
    --end if;
    l_new_relat_id:=:new.relat_id;
  elsif updating then
    --���������� ���, �.�. ��� ������
    c_charges.trg_c_kart_pr_bd_fio := :old.fio;
    c_charges.trg_c_kart_pr_bd_lsk := :old.lsk;

    :new.k_fam := initcap(:new.k_fam);
    :new.k_im  := initcap(:new.k_im);
    :new.k_ot  := initcap(:new.k_ot);
    :new.fio   := :new.k_fam || ' ' || :new.k_im || ' ' || :new.k_ot;
    --��� �������� ���-�� ����������� � �������� c_kart_pr_auid
    c_charges.tab_lsk.extend;
    c_charges.tab_lsk(c_charges.tab_lsk.last) := :old.lsk;
    --���������� ������� ������������, ��� ����������� ��������� � ���������
    c_charges.tab_c_kart_pr_id.extend;
    c_charges.tab_c_kart_pr_id(c_charges.tab_c_kart_pr_id.last) := :old.id;
    --���� ������ �� ������� ������
    if nvl(c_charges.trg_proc_next_month, 0) = 0 then
      aud_text_ := '(���������)';
    end if;
    --�������� ������, ���� �������, ���� �� ����������
    if :new.status <> 4 then
      --      :new.dat_ub:=null;
      :new.fk_ub       := null;
      :new.fk_to_cntr  := null;
      :new.fk_to_regn  := null;
      :new.fk_to_distr := null;
      :new.fk_to_kul   := null;
      :new.to_town     := null;
      :new.to_nd       := null;
      :new.to_kw       := null;
    end if;
    c_charges.nabor_lsk_ := :old.lsk;
    if (:new.fio <> :old.fio and :new.fio is not null and
       :old.fio is not null) or (:new.fio is null and :old.fio is not null) or
       (:new.fio is not null and :old.fio is null) then
      aud_text_ := aud_text_ ||
                   logger.log_text('�.�.�.',
                                   trim(:old.fio),
                                   trim(:new.fio));
    end if;
    lsk_ := :old.lsk;
    if nvl(:new.status, 0) <> nvl(:old.status, 0) then
      select name into txt_ from c_status_pr t where t.id = :old.status;
      begin
        select name into txt2_ from c_status_pr t where t.id = :new.status;
      exception
        when others then
          Raise_application_error(-20000, :old.id || '-' || :new.status);
      end;
      aud_text_ := aud_text_ ||
                   logger.log_text('C�����', trim(txt_), trim(txt2_));
    end if;
    -- �������� ��� ������������ � kart, � �������� c_kart_pr_auid
    --if nvl(:new.relat_id, 0) = 11 or nvl(:old.relat_id, 0) = 11 then
    --  flag_kv_ := 1;
    --end if;
    l_new_relat_id:=:new.relat_id;
    l_old_relat_id:=:old.relat_id;
  elsif deleting then
    --���������� ���, �.�. ��� ������
    c_charges.trg_c_kart_pr_bd_fio := :old.fio;
    c_charges.trg_c_kart_pr_bd_lsk := :old.lsk;

    --��� �������� ���-�� ����������� � �������� c_kart_pr_auid
    c_charges.tab_lsk.extend;
    c_charges.tab_lsk(c_charges.tab_lsk.last) := :old.lsk;

    if updating and
       (:new.status <> :old.status or :new.dat_ub <> :old.dat_ub or
       :new.dat_prop <> :old.dat_prop) or inserting then
      --���������� ������� ������������, ��� ����������� ��������� � ���������
      --���� ���� �������� �������� ����
      c_charges.tab_c_kart_pr_id.extend;
      c_charges.tab_c_kart_pr_id(c_charges.tab_c_kart_pr_id.last) := :old.id;
    end if;

    c_charges.nabor_lsk_ := :old.lsk;
    aud_text_            := '������ �����������: ' || trim(:old.fio);
    lsk_                 := :old.lsk;
    -- �������� ��� ������������ � kart, � �������� c_kart_pr_auid
    --if nvl(:old.relat_id, 0) = 11 then
    --  flag_kv_ := 1;
    --end if;
    l_old_relat_id:=:old.relat_id;
  end if;

  select count(*) into l_relat_cnt 
    from relations r where r.id in (l_new_relat_id,l_old_relat_id) and r.fk_relat_tp=1;

  if l_relat_cnt = 1 then
    -- ��������� ���������������
    c_charges.chng_relat_id := 1;
  end if;

  if length(aud_text_) > 0 then
    aud_text_ := '��������� ������ ������������: ' || aud_text_;
    logger.log_act(lsk_, aud_text_, 2);
  end if;

end;
/

