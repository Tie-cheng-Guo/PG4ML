EXTENSION = pg4ml
EXTVERSION = $(shell grep default_version $(EXTENSION).control | \
                sed -e "s/default_version[[:space:]]*=[[:space:]]*'\([^']*\)'/\1/")


$(EXTENSION)--$(EXTVERSION).sql: FORCE
	$(shell sh gen_sql_files.sh)

DATA = $(EXTENSION)--$(EXTVERSION).sql $(EXTENSION)--2.0--$(EXTVERSION).sql

REGRESS = 10_install/unit_test
REGRESS_OPTS = --no-locale --load-extension=tablefunc --load-extension=cube --load-extension=plpython3u --load-extension=pg4ml
EXTRA_INSTALL += contrib/tablefunc
EXTRA_INSTALL += contrib/cube


ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/pg4ml
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

FORCE:
.PHONY: FORCE