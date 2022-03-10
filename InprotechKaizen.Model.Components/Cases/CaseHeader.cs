using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Extensions;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface ICaseHeaderPartial
    {
        Task<CaseHeader> Retrieve(int userIdentityId, string culture, int caseKey);
    }

    public class CaseHeaderPartial : ICaseHeaderPartial
    {
        const string Command = "csw_appsCaseHeaderAndNames";

        readonly IDbContext _dbContext;
        readonly INameAuthorization _nameAuthorization;

        public CaseHeaderPartial(IDbContext dbContext, INameAuthorization nameAuthorization)
        {
            _dbContext = dbContext;
            _nameAuthorization = nameAuthorization;
        }

        public async Task<CaseHeader> Retrieve(int userIdentityId, string culture, int caseKey)
        {
            CaseHeader header;
            using (var dbCommand = _dbContext.CreateStoredProcedureCommand(Command))
            {
                dbCommand.Parameters.AddWithValue("pnUserIdentityId", userIdentityId);
                dbCommand.Parameters.AddWithValue("psCulture", culture);
                dbCommand.Parameters.AddWithValue("pnCaseKey", caseKey);
                using (var reader = await dbCommand.ExecuteReaderAsync())
                {
                    header = reader.MapTo<CaseHeader>().Single();
                    reader.NextResult();
                    header.Names = reader.MapTo<CaseSummaryName>();
                }
            }
            if (header.Names.Any())
            {
                var accessibleNames = (await _nameAuthorization.AccessibleNames(header.Names.Select(d => d.NameKey).Distinct().ToArray())).ToArray();
                foreach (var t in header.Names)
                {
                    if (!accessibleNames.Contains(t.NameKey))
                    {
                        t.RestrictAccess = true;
                        t.Name = null;
                    }
                }
            }
            return header;
        }
    }

    public class CaseHeader
    {
        public int CaseKey { get; set; }
        public string Title { get; set; }
        public string CaseStatusDescription { get; set; }
        public string RenewalStatusDescription { get; set; }
        public string CountryName { get; set; }
        public string PropertyTypeDescription { get; set; }
        public string CaseCategoryDescription { get; set; }
        public string SubTypeDescription { get; set; }
        public string FileLocation { get; set; }
        public string CaseOffice { get; set; }
        public string RenewalInstruction { get; set; }
        public bool? IsCRM { get; set; }
        public string Classes { get; set; }
        public int? TotalClasses { get; set; }
        public string BasisDescription {get; set; }
        public IEnumerable<CaseSummaryName> Names { get; set; }
    }

    public class CaseSummaryName
    {
        public int CaseKey { get; set; }
        public string NameTypeKey { get; set; }
        public int NameKey { get; set; }
        public short NameSequence { get; set; }
        public string NameTypeDescription { get; set; }
        public string Name { get; set; }
        public string NameCode { get; set; }
        public decimal? ShowNameCodeRaw { get; set; }
        public string NameAndCode => ((ShowNameCode) Convert.ToInt32(ShowNameCodeRaw)).Format(Name, NameCode);
        public string RowKey { get; set; }
        public short NameDisplayOrder { get; set; }
        public bool RestrictAccess { get; set; }
        public string NameReference { get; set; }
        public string DisplayMainEmail { get; set; }
    }
}
