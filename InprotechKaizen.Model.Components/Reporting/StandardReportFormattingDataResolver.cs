using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Reporting
{
    public interface IStandardReportFormattingDataResolver
    {
        Task<XElement> Resolve(int userIdentityId, string culture);
    }

    public class StandardReportFormattingDataResolver : IStandardReportFormattingDataResolver
    {
        readonly IDbContext _dbContext;
        readonly IDisplayFormattedName _displayFormattedName;
        readonly ILegacyFormattingDataProvider _legacyFormattingDataProvider;
        readonly ISiteControlReader _siteControlReader;

        public StandardReportFormattingDataResolver(IDbContext dbContext,
                                                    ILegacyFormattingDataProvider legacyFormattingDataProvider,
                                                    ISiteControlReader siteControlReader,
                                                    IDisplayFormattedName displayFormattedName)
        {
            _dbContext = dbContext;
            _legacyFormattingDataProvider = legacyFormattingDataProvider;
            _siteControlReader = siteControlReader;
            _displayFormattedName = displayFormattedName;
        }

        public async Task<XElement> Resolve(int userIdentityId, string culture)
        {
            var formattingData = _legacyFormattingDataProvider.Provide(culture);

            var homeNameId = _siteControlReader.Read<int>(SiteControls.HomeNameNo);

            var user = await _dbContext.Set<User>()
                                       .Where(n => n.Id == userIdentityId)
                                       .Select(_ => new
                                       {
                                           _.NameId,
                                           _.IsExternalUser
                                       }).SingleAsync();

            var formattedNames = await _displayFormattedName.For(new[] { homeNameId, user.NameId });

            return new XElement("FormattingData",
                                new XElement("Format", new XAttribute("name", "DateFormat"), formattingData.DateFormat),
                                new XElement("Format", new XAttribute("name", "TimeFormat"), formattingData.TimeFormat),
                                new XElement("Format", new XAttribute("name", "CurrencyFormat"), formattingData.CurrencyFormat),
                                new XElement("Format", new XAttribute("name", "LocalCurrencyFormat"), formattingData.LocalCurrencyFormat),
                                new XElement("Format", new XAttribute("name", "LocalCurrencyFormatWithSymbol"), formattingData.LocalCurrencyFormatWithSymbol),
                                new XElement("Format", new XAttribute("name", "CurrencyDecimalInfo"),
                                             formattingData.CurrencyDecimalPlaces
                                                           .Select(cdp => new XElement("CurrencyDecimalPlaces",
                                                                                       new XAttribute("DecimalPlaces", cdp.Value),
                                                                                       new XAttribute("CurrencyCode", cdp.Key)))
                                            ),
                                new XElement("Data",
                                             new XAttribute("name", "UserName"),
                                             new XAttribute("IsExternal", user.IsExternalUser), formattedNames.Get(user.NameId).Name),
                                new XElement("Data",
                                             new XAttribute("name", "FirmName"), formattedNames.Get(homeNameId).Name));
        }
    }
}