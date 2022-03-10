using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Screens;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Program = InprotechKaizen.Model.Security.Program;

namespace Inprotech.Web.Names.Details
{
    public class NameViewData
    {
        public string NameCode { get; set; }
        public string Name { get; set; }
        public string Program { get; set; }
        public NameViewSections Sections { get; set; }
        public IEnumerable<KeyValuePair<string, string>> SupplierTypes { get; set; }
        public IEnumerable<KeyValuePair<string, string>> TaxTreatments { get; set; }
        public IEnumerable<KeyValuePair<string, string>> TaxRates { get; set; }
        public IEnumerable<KeyValuePair<string, string>> PaymentTerms { get; set; }
        public int NameId { get; set; }
        public int? NameCriteriaId { get; set; }
        public IEnumerable<KeyValuePair<string, string>> PaymentMethods { get; set; }
        public IEnumerable<KeyValuePair<string, string>> IntoBankAccounts { get; set; }
        public IEnumerable<KeyValuePair<string, string>> PaymentRestrictions { get; set; }
        public IEnumerable<KeyValuePair<string, string>> ReasonsForRestrictions { get; set; }
        public bool CanMaintainName { get; set; }
        public bool CanGenerateWordDocument { get; set; }
        public bool CanGeneratePdfDocument { get; set; }
    }

    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/name")]
    public class NameViewController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly INameViewResolver _nameViewResolver;
        readonly INameViewSectionsResolver _nameViewSectionResolver;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;
        readonly ISupplierDetailsMaintenance _supplierDetailsMaintenance;
        readonly ITrustAccountingResolver _trustAccountingResolver;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IListPrograms _listNamePrograms;

        public NameViewController(IDbContext dbContext,
                                  ISecurityContext securityContext,
                                  ISiteControlReader siteControlReader,
                                  INameViewSectionsResolver nameViewSectionResolver,
                                  INameViewResolver nameViewResolver,
                                  ISupplierDetailsMaintenance supplierDetailsMaintenance,
                                  ITrustAccountingResolver trustAccountingResolver,
                                  ITaskSecurityProvider taskSecurityProvider,
                                  IListPrograms listNamePrograms)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _siteControlReader = siteControlReader;
            _nameViewSectionResolver = nameViewSectionResolver;
            _nameViewResolver = nameViewResolver;
            _supplierDetailsMaintenance = supplierDetailsMaintenance;
            _trustAccountingResolver = trustAccountingResolver;
            _taskSecurityProvider = taskSecurityProvider;
            _listNamePrograms = listNamePrograms;
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("nameview/{nameId:int}/{programId?}")]
        public async Task<NameViewData> GetNameView(int nameId, string programId = null)
        {
            var name = _dbContext.Set<Name>().SingleOrDefault(v => v.Id == nameId);
            if (name == null)
            {
                throw new HttpException(404, "Unable to find the name.");
            }
            
            var program = await GetNameProgram(programId);
            var sections = await _nameViewSectionResolver.Resolve(nameId, program.Id);

            var supplierTypes = _nameViewResolver.GetSupplierTypes();
            var taxTreatments = _nameViewResolver.GetTaxTreatment();
            var taxRates = _nameViewResolver.GetTaxRates();
            var paymentTerms = _nameViewResolver.GetPaymentTerms();
            var paymentMethods = _nameViewResolver.GetPaymentMethods();
            var intoBankAccounts = _nameViewResolver.GetIntoBankAccounts(nameId);
            var paymentRestrictions = _nameViewResolver.GetPaymentRestrictions();
            var reasonsForRestrictions = _nameViewResolver.GetReasonsForRestrictions();
            var canMaintainName = _nameViewResolver.CheckNameMaintainPermission();

            return new NameViewData
            {
                NameCode = name.NameCode, 
                Name = name.Formatted(), 
                Program = program.Name,
                Sections = sections,
                SupplierTypes = supplierTypes,
                TaxTreatments = taxTreatments,
                TaxRates = taxRates,
                PaymentTerms = paymentTerms,
                NameId = nameId,
                NameCriteriaId = sections.ScreenNameCriteria,
                PaymentMethods = paymentMethods,
                IntoBankAccounts = intoBankAccounts,
                PaymentRestrictions = paymentRestrictions,
                ReasonsForRestrictions = reasonsForRestrictions,
                CanMaintainName = canMaintainName,
                CanGenerateWordDocument = _taskSecurityProvider.HasAccessTo(ApplicationTask.CreateMsWordDocument),
                CanGeneratePdfDocument = _taskSecurityProvider.HasAccessTo(ApplicationTask.CreatePdfDocument) && _siteControlReader.Read<bool>(SiteControls.PDFFormFilling)
            };
        }

        public async Task<Program> GetNameProgram(string programId = null)
        {
            var profileId = _securityContext.User?.Profile?.Id;
            var defaultProgram = _listNamePrograms.GetDefaultNameProgram();
            if (profileId == null) return await _dbContext.Set<Program>().SingleOrDefaultAsync(v => v.Id == defaultProgram);
            
            var matchingProgram = await (from program in _dbContext.Set<Program>()
                                   join pp in _dbContext.Set<ProfileProgram>() on program.Id equals pp.ProgramId
                                   where pp.ProfileId == profileId && pp.ProgramId == programId
                                   select program).FirstOrDefaultAsync();

            return matchingProgram ?? await _dbContext.Set<Program>().SingleOrDefaultAsync(v => v.Id == defaultProgram);
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("{nameId:int}/supplier-details")]
        public async Task<NameSupplierDetailData> GetSupplierDetails(int nameId)
        {
            return await _supplierDetailsMaintenance.GetSupplierDetails(nameId);
        }

        [HttpPost]
        [RequiresNameAuthorization]
        [Route("{nameId:int}/trust-accounting")]
        public async Task<ResultResponse> GetTrustAccountingData(int nameId, CommonQueryParameters reqParams)
        {
            return await _trustAccountingResolver.Resolve(nameId, reqParams);
        }

        [HttpGet]
        [RequiresNameAuthorization]
        [Route("trust-accounting-details")]
        public async Task<ResultDetailResponse> GetTrustAccountingDetails(int nameId, int bankId, int bankSeqId, int entityId,
                                                                          [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                                          CommonQueryParameters qp = null)
        {
            return await _trustAccountingResolver.Details(nameId, bankId, bankSeqId, entityId, qp);
        }
    }
}