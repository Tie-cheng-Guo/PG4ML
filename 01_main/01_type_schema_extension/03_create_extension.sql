create extension if not exists tablefunc;

create extension if not exists cube;

-- -- 需要安装 plpython3u
--   dnf -y install postgresql13-plpython3.x86_64
-- --   dnf -y install postgresql13-pltcl.x86_64
--   pip3 install numpy --timeout=100 -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com
create extension if not exists plpython3u;

-- -- for pg 11
-- create extension if not exists pgcrypto;