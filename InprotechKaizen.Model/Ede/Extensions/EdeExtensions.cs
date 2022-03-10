using System;
using System.Data.Entity;
using System.Linq;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Ede.Extensions
{
    public static class EdeExtensions
    {
        public static Name EdeSenderNameFor(this IDbSet<NameAlias> nameAliases, string senderToMatch)
        {
            if (string.IsNullOrWhiteSpace(senderToMatch)) throw new ArgumentNullException("senderToMatch");

            return nameAliases.EdeSenders(senderToMatch).Single().Name;
        }

        public static IQueryable<NameAlias> EdeSenders(this IDbSet<NameAlias> nameAliases, string senderToMatch)
        {
            if (string.IsNullOrWhiteSpace(senderToMatch)) throw new ArgumentNullException("senderToMatch");

            return nameAliases.Where(
                n => n.AliasType.Code == KnownAliasTypes.EdeIdentifier
                     && n.Alias == senderToMatch
                     && n.Country == null
                     && n.PropertyType == null);
        }
    }
}