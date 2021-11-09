# Copyright (c) 2021, University of Oslo
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# Neither the name of the HISP project nor the names of its contributors may
# be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Adapted with permission from original work by Jim Grace, Ben Guiraldi and Timothy Harding
# of the DATIM team. 

CREATE or REPLACE function fixSortOrder
	(tbl text, key text,sort_column text, start integer) returns boolean as
$$
DECLARE
	resortObject record;
BEGIN
CREATE TEMP TABLE IF NOT EXISTS _fixsortorder (
    temp integer
) ON COMMIT DROP;

	execute format('insert into _fixsortorder (select distinct %s from %s)', key, tbl);

    for resortObject in (select temp from _fixsortorder) loop
		execute format('update %s
						set %s = -t.i
						from (select row_number() over (order by %s) as i,
                         %s,
                         %s from
                        %s where
                        %s = %s order by %s) t
						where %s.%s = %s and t.%s = %s.%s',
			 tbl,
             sort_column,
             sort_column,
             key,
             sort_column,
             tbl,
             key,
             resortObject.temp,
             sort_column,
             tbl,
             key,
             resortObject.temp,
             sort_column,
             tbl,
             sort_column);
	end loop;
	execute format('update %s set %s = -(%s + 1) + %s', tbl,sort_column, sort_column, start);
	return true;
end;
$$
language plpgsql volatile;