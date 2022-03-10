using System;
using System.Linq;
using System.Text.RegularExpressions;
using Inprotech.Contracts;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Accounting.VatReturns
{
    public interface IHmrcTokenResolver
    {
        HmrcTokens Resolve(string vrn);
        void SaveTokens(HmrcTokens tokens, string vrn);
    }
    public class HmrcTokenResolver : IHmrcTokenResolver
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ICryptoService _cryptoService;
        public HmrcTokenResolver(IDbContext dbContext, ISecurityContext securityContext, ICryptoService cryptoService)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _cryptoService = cryptoService;
        }

        public HmrcTokens Resolve(string vrn)
        {
            var validVrn = ProviderName(vrn);
            var result = _dbContext.Set<ExternalCredentials>().SingleOrDefault(v => v.User.Id == _securityContext.User.Id && v.ProviderName == validVrn);
            if (result == null)
            {
                return null;
            }
            var tokens = JObject.Parse(_cryptoService.Decrypt(result.Password)).ToObject<HmrcTokens>();

            return tokens;
        }

        public void SaveTokens(HmrcTokens tokens, string vrn)
        {
            var validVrn = ProviderName(vrn);
            var externalCredentials = _dbContext.Set<ExternalCredentials>().SingleOrDefault(v => v.User.Id == _securityContext.User.Id && v.ProviderName == validVrn);

            if (externalCredentials == null)
            {
                _dbContext.Set<ExternalCredentials>()
                    .Add(new ExternalCredentials(_securityContext.User, _securityContext.User.UserName, _cryptoService.Encrypt(JObject.FromObject(tokens).ToString()), validVrn));
            }
            else
            {
                externalCredentials.Password = _cryptoService.Encrypt(JObject.FromObject(tokens).ToString());
            }

            _dbContext.SaveChanges();
        }

        public string ProviderName(string vrn)
        {
            if (string.IsNullOrWhiteSpace(vrn))
                return KnownExternalSettings.HmrcVatSettings;

            if (!Regex.IsMatch(vrn, @"^(GB)?([0-9]{9}|[0-9]{12})$"))
            {
                throw new Exception($"The VRN ({vrn}) is invalid: it should be a 9 digit number or a 12 digit number.");
            }
            
            return KnownExternalSettings.HmrcVatSettings + vrn;
        }
    }

    public class HmrcTokens
    {
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
    }
}
