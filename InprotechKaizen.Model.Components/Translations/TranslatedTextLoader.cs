using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Translations;

namespace InprotechKaizen.Model.Components.Translations
{
    interface ITranslatedTextLoader
    {
        IDictionary<int, string> Load(LookupCulture lookupCulture, IEnumerable<int> tids);
    }

    class TranslatedTextLoader : ITranslatedTextLoader
    {
        readonly IDbContext _dbContext;

        public TranslatedTextLoader(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public IDictionary<int, string> Load(LookupCulture lookupCulture, IEnumerable<int> tids)
        {
            var r = Queryable.Where<TranslatedText>(_dbContext.Set<TranslatedText>(), tt => (tt.CultureId == lookupCulture.Requested || tt.CultureId == lookupCulture.Fallback) && tids.Contains(tt.Tid) && !tt.HasSourceChanged)
                             .ToArray();

            var requested = r.Where(tt => tt.CultureId == lookupCulture.Requested).ToArray();
            var fallback = r.Where(tt => tt.CultureId == lookupCulture.Fallback).ToArray();

            var ec = new Inprotech.Infrastructure.Extensions.LambdaEqualityComparer<TranslatedText>((x, y) =>
            {
                if (ReferenceEquals(x, y)) return true;
                if (ReferenceEquals(x, null)) return false;
                if (ReferenceEquals(y, null)) return false;
                if (x.GetType() != y.GetType()) return false;
                return x.Tid == y.Tid;
            }, t => t.Tid);

            r = requested.Concat(fallback.Except(requested, ec)).ToArray();

            return r.ToDictionary(a => a.Tid, a => a.ShortText ?? a.LongText);
        }

    }
}
