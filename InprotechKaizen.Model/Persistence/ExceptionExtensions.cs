using System;
using System.Data.SqlClient;

namespace InprotechKaizen.Model.Persistence
{
    public static class ExceptionExtensions
    {
        public static bool IsForeignKeyConstraintViolation(this Exception ex)
        {
            var sql = ex.FindBaseSqlException();
            if (sql == null)
                return false;

            var found = false;
            while (ex != null && !found)
            {
                foreach (var error in sql.Errors)
                {
                    var sqlError = error as SqlError;
                    if (sqlError == null) continue;
                    if (sqlError.Number == 547)
                    {
                        found = true;
                        break;
                    }
                }
            }

            return found;
        }

        static SqlException FindBaseSqlException(this Exception ex)
        {
            return ex as SqlException ?? ex.GetBaseException() as SqlException;
        }
    }
}