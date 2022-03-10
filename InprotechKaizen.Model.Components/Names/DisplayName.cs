using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Names
{
    public interface IDisplayFormattedName
    {
        Task<Dictionary<int, NameFormatted>> For(int[] nameIds,
                                                    NameStyles fallbackNameStyle = NameStyles.Default);

        Task<string> For(int nameId, NameStyles fallbackNameStyle = NameStyles.Default);
    }

    public class DisplayFormattedName : IDisplayFormattedName
    {
        readonly IDbContext _dbContext;

        public DisplayFormattedName(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<Dictionary<int, NameFormatted>> For(int[] nameIds, NameStyles fallbackNameStyle = NameStyles.Default)
        {
            var distinctNameIds = nameIds.Distinct();
            return (await (from n in _dbContext.Set<Name>()
                           where distinctNameIds.Contains(n.Id)
                           select new
                           {
                               NameId = n.Id,
                               n.NameCode,
                               n.FirstName,
                               n.MiddleName,
                               n.LastName,
                               n.Suffix,
                               n.Title,
                               n.NameStyle,
                               NationalityNameStyle = n.Nationality != null ? n.Nationality.NameStyleId : null
                           })
                    .ToArrayAsync())
                .ToDictionary(k => k.NameId, v => new NameFormatted
                {
                    NameId = v.NameId,
                    Name = FormattedName.For(v.LastName, v.FirstName, v.Title, v.MiddleName, v.Suffix, EffectiveNameStyle(v.NameStyle, v.NationalityNameStyle, fallbackNameStyle)),
                    NameCode = v.NameCode
                });
        }

        public async Task<string> For(int nameId, NameStyles fallbackNameStyle = NameStyles.Default)
        {

            var formattedNames = await For(new[]{nameId});

            return formattedNames[nameId] != null ? formattedNames[nameId].Name : string.Empty;
        }

        static NameStyles EffectiveNameStyle(int? nameStyle, int? nationalityNameStyle, NameStyles fallbackNameStyle)
        {
            var dataNameStyle = nameStyle ?? nationalityNameStyle;
            return dataNameStyle != null
                ? (NameStyles) dataNameStyle
                : fallbackNameStyle;
        }
    }
}