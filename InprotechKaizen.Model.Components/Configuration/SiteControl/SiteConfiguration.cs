using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Configuration.SiteControl
{
    public interface ISiteConfiguration
    {
        Name HomeName();

        Country HomeCountry();

        bool KeepSpecificationHistory { get; }

        bool TransactionReason { get; }

        int? ReasonIpOfficeVerification { get; }

        int? ReasonInternalChange { get; }

        string DatabaseLanguageCode { get; }

        string ProductSupportEmail { get; }
    }

    public class SiteConfiguration : ISiteConfiguration
    {
        readonly IDbContext _dbContext;

        Name _name;
        Country _country;
        bool? _keepSpecificationHistory;
        bool? _transactionReason;
        int? _reasonIpOfficeVerification;
        int? _reasonInternalChange;
        string _databaseLanguage;
        string _productSupportEmail;
        public SiteConfiguration(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public Name HomeName()
        {
            if (_name != null) return _name;

            var homeNameSiteControl =
                _dbContext.Set<Model.Configuration.SiteControl.SiteControl>().Single(s => s.ControlId == SiteControls.HomeNameNo).IntegerValue;

            return _name = _dbContext.Set<Name>()
                .Single(n => n.Id == homeNameSiteControl);
        }

        public Country HomeCountry()
        {
            if (_country != null) return _country;

            var homeCountrySiteControl =
                _dbContext.Set<Model.Configuration.SiteControl.SiteControl>().Single(s => s.ControlId == SiteControls.HOMECOUNTRY).StringValue;

            return _country = _dbContext.Set<Country>()
                .Single(c => c.Id == homeCountrySiteControl);
        }

        public bool KeepSpecificationHistory
        {
            get
            {
                if (_keepSpecificationHistory.HasValue)
                    return _keepSpecificationHistory.Value;

                return (_keepSpecificationHistory =
                        _dbContext.Set<Model.Configuration.SiteControl.SiteControl>().Single(s => s.ControlId == SiteControls.KEEPSPECIHISTORY).BooleanValue).GetValueOrDefault();
            }
        }

        public bool TransactionReason
        {
            get
            {
                if (_transactionReason.HasValue)
                    return _transactionReason.Value;

                return (_transactionReason =
                    _dbContext.Set<Model.Configuration.SiteControl.SiteControl>().Single(s => s.ControlId == SiteControls.TransactionReason).BooleanValue).GetValueOrDefault();
            }
        }

        public int? ReasonIpOfficeVerification
        {
            get
            {
                if (_reasonIpOfficeVerification.HasValue)
                    return _reasonIpOfficeVerification;

                return _reasonIpOfficeVerification =
                    _dbContext.Set<Model.Configuration.SiteControl.SiteControl>().Single(s => s.ControlId == SiteControls.TRIPOfficeVerification).IntegerValue;
            }
        }

        public int? ReasonInternalChange
        {
            get
            {
                if (_reasonInternalChange.HasValue)
                    return _reasonInternalChange;

                return _reasonInternalChange =
                    _dbContext.Set<Model.Configuration.SiteControl.SiteControl>().Single(s => s.ControlId == SiteControls.TRInternalChange).IntegerValue;
            }
        }

        public string DatabaseLanguageCode
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(_databaseLanguage))
                    return _databaseLanguage;

                var siteControl = _dbContext.Set<Model.Configuration.SiteControl.SiteControl>();
                var tableCodes = _dbContext.Set<TableCode>();

                _databaseLanguage = (from s in siteControl
                                     join t in tableCodes on new {tcId = (int?) s.IntegerValue} equals new {tcId = (int?) t.Id} into l1
                                     from t in l1.DefaultIfEmpty()
                                     where s.ControlId == SiteControls.LANGUAGE && t.TableTypeId == (short) TableTypes.Language
                                     select t.UserCode).SingleOrDefault() ?? "en";

                return _databaseLanguage;
            }
        }

        public string ProductSupportEmail
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(_productSupportEmail))
                    return _productSupportEmail;

                _productSupportEmail = _dbContext.Set<Model.Configuration.SiteControl.SiteControl>()
                                                 .SingleOrDefault(_ => _.ControlId == SiteControls.ProductSupportEmail)
                                                 ?.StringValue;

                return _productSupportEmail;
            }
        }
    }
}