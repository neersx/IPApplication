using System;
using System.Linq;

namespace InprotechKaizen.Model.Persistence
{
    public class SqlDbArtifacts : IDbArtifacts
    {
        const string Command = @"select 1 from sysobjects where id = object_id('{0}') and xtype in ({1})";

        readonly IDbContext _dbContext;

        public SqlDbArtifacts(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbContext = dbContext;
        }

        public bool Exists(string name, params string[] sysObjects)
        {
            if (sysObjects == null || sysObjects.Length == 0)
                return false;

            object[] arguments = { name, string.Join(",", sysObjects) };

            var result = _dbContext.SqlQuery<int>(string.Format(Command, arguments)).FirstOrDefault() > 0;

            return result;
        }
    }
}
