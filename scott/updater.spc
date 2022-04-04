create or replace package scott.UPDATER is

procedure send_message(msg_ in messages.text%type);
procedure set_ver(ver_ in number, type_ in number);
procedure del_types;

end UPDATER;
/

