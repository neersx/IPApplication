using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Translations;

namespace InprotechKaizen.Model.Components.Translations
{
    interface ITranslationMetadataLoader
    {
        IDictionary<Type, IEnumerable<TranslationSource>> Load(IEnumerable<Type> types);
    }

    class TranslationMetadataLoader : ITranslationMetadataLoader
    {
        readonly IDbContext _dbContext;

        public TranslationMetadataLoader(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public IDictionary<Type, IEnumerable<TranslationSource>> Load(IEnumerable<Type> types)
        {
            var tableNameToType = types.ToDictionary(Utilities.GetTableName, a => a);
            var tableNames = tableNameToType.Keys;

            var source = Queryable.Where<TranslationSource>(_dbContext.Set<TranslationSource>(), ts => tableNames.Contains(ts.TableName) && ts.IsInUse)
                                  .ToArray();

            return source.GroupBy(a => tableNameToType[a.TableName], a => a)
                .ToDictionary(a => a.Key, a => a.AsEnumerable());
        }
    }
}