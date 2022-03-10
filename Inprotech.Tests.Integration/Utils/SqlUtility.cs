using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.Utils
{
    public static class SqlUtility
    {
        public static List<string> SplitSqlStatements(string sqlScript)
        {
            // Split by "GO" statements
            var statements = Regex.Split(
                                         sqlScript,
                                         @"^\s*GO\s* ($ | \-\- .*$)",
                                         RegexOptions.Multiline |
                                         RegexOptions.IgnorePatternWhitespace |
                                         RegexOptions.IgnoreCase);

            // Remove empties, trim, and return
            return statements
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Select(x => x.Trim(' ', '\r', '\n'))
                .ToList();
        }

        public static void RenameStoredProcedureAsBackup(this IDbContext context, string proc)
        {
            var sql = $@"
if exists(select * from sysobjects where name = '{proc}' and xtype = 'P')
begin
    if exists(select * from sysobjects where name = '{proc}_backup' and xtype = 'P')
    begin
        drop procedure {proc}_backup
    end

    exec sp_rename '{proc}', '{proc}_backup'
end
";
            context.CreateSqlCommand(sql).ExecuteNonQuery();
        }

        public static void RestoreStoredProcedureFromBackup(this IDbContext context, string proc)
        {
            var sql = $@"
if exists(select * from sysobjects where name = '{proc}_backup' and xtype = 'P')
begin
    if exists(select * from sysobjects where name = '{proc}' and xtype = 'P')
    begin
        drop procedure {proc}
    end

    exec sp_rename '{proc}_backup', '{proc}'
end
";
            context.CreateSqlCommand(sql).ExecuteNonQuery();
        }
    }
}