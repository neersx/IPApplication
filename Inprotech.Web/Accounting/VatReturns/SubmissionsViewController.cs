using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Web.Accounting.VatReturns
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.HmrcVatSubmission)]
    [RoutePrefix("api/accounting/vat")]
    public class SubmissionsViewController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;
        readonly IVatReturnStore _vatReturnStore;
        readonly IHmrcAuthenticator _hmrcAuthenticator;
        readonly IHmrcClient _hmrcClient;
        readonly IVatReturnsExporter _vatReturnExporter;
        readonly Func<Guid> _guidFactory;
        readonly IHmrcTokenResolver _hmrcToken;

        public SubmissionsViewController(IDbContext dbContext, IHmrcAuthenticator hmrcAuthenticator, IHmrcClient hmrcClient, IDocItemRunner docItemRunner, IVatReturnStore vatReturnStore, IVatReturnsExporter vatReturnExporter, Func<Guid> guidFactory, IHmrcTokenResolver hmrcToken)
        {
            _dbContext = dbContext;
            _hmrcAuthenticator = hmrcAuthenticator;
            _hmrcClient = hmrcClient;
            _docItemRunner = docItemRunner;
            _vatReturnStore = vatReturnStore;
            _vatReturnExporter = vatReturnExporter;
            _guidFactory = guidFactory;
            _hmrcToken = hmrcToken;
        }

        [Route("view")]
        public dynamic Get(string state = null)
        {
            return new
            {
                StateId = state,
                EntityNames = GetEntityNames(),
                DeviceId = GetDeviceId()
            };
        }

        public async Task<dynamic> Authorise(string vrn)
        {
            var stateKey = Guid.NewGuid().ToString();
            var response = await _hmrcAuthenticator.GetAuthCode(string.Join(",", stateKey, vrn));
            return new
            {
                ReadyToRedirect = response.StatusCode,
                LoginUri = response.ResponseUri,
                StateKey = stateKey
            };
        }

        [HttpGet]
        [Route("obligations")]
        public async Task<dynamic> GetObligations([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                                  VatObligationsQuery q = null)
        {
            if (q == null) throw new HttpResponseException(HttpStatusCode.BadRequest);
            if (string.IsNullOrWhiteSpace(q.TaxNo)) throw new ArgumentNullException(nameof(q.TaxNo));

            var tokens = _hmrcToken.Resolve(q.TaxNo);
            if (tokens == null)
            {
                return Authorise(q.TaxNo);
            }

            if (string.IsNullOrWhiteSpace(tokens.AccessToken))
                throw new HttpResponseException(HttpStatusCode.Unauthorized);
            if (string.IsNullOrWhiteSpace(tokens.RefreshToken))
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            return await VatObligations(q, tokens.AccessToken, tokens.RefreshToken, Request);
        }

        [HttpGet]
        [Route("vatData")]
        public dynamic GetVatData([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                  VatDataRetrievalParams q = null)
        {
            if (q == null) throw new HttpResponseException(HttpStatusCode.BadRequest);
            var vatItemName = KnownVatDocItems.GetValue(q.VatBoxNumber);

            var item = _dbContext.Set<DocItem>().SingleOrDefault(v => v.Name == vatItemName);
            var p = new Dictionary<string, object>
            {
                {"pnEntityNo", q.EntityNameNo},
                {"pdTransDateStart", q.FromDate},
                {"pdTransDateEnd", q.ToDate}
            };

            decimal? vatAmount = null;
            if (item != null)
            {
                vatAmount = _docItemRunner.Run(item.Id, p).ScalarValueOrDefault<decimal?>();
            }

            return new
            {
                Value = vatAmount
            };
        }

        [HttpPost]
        [Route("submit")]
        public async Task<dynamic> Submit(VatSubmissionRequest vatData)
        {
            if (vatData == null) throw new HttpResponseException(HttpStatusCode.BadRequest);
            if (string.IsNullOrWhiteSpace(vatData.VatNo)) throw new ArgumentNullException("VATNo");
            if (!int.TryParse(vatData.EntityNo, out var entityNo)) throw new ArgumentNullException("EntityNo");

            var tokens = _hmrcToken.Resolve(vatData.VatNo);
            if (tokens == null)
                throw new HttpResponseException(HttpStatusCode.Unauthorized);

            var result = await _hmrcClient.SubmitVatReturn(GetVatData(vatData), vatData.VatNo, tokens.AccessToken, Request);
            _vatReturnStore.Add(entityNo, vatData.PeriodKey, result.Data, result.IsSuccessful, vatData.VatNo);
            var guid = _vatReturnExporter.ExportVatReturnToPdf(vatData, result, false);

            return new
            {
                result.Data,
                PdfStorageId = guid
            };
        }

        [HttpGet]
        [Route("~/accounting/vat/{pdfid}/exportToPdf/{filename}")]
        public HttpResponseMessage ExportToPdf(string pdfid, string filename)
        {
            if (string.IsNullOrWhiteSpace(pdfid)) throw new ArgumentNullException(nameof(pdfid));
            if (string.IsNullOrWhiteSpace(filename)) throw new ArgumentNullException(nameof(filename));

            byte[] pdfBytes = new byte[0];
            using (var stream = new MemoryStream())
            {
                _vatReturnExporter.ReturnVatPdf(stream, pdfid, filename);
                pdfBytes = stream.ToArray();
            }

            var result = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StreamContent(new MemoryStream(pdfBytes))
            };
            result.Content.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");
            return result;
        }

        [HttpGet]
        [Route("vatReturn")]
        public async Task<dynamic> GetVatReturn([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] VatSubmissionRequest q)
        {
            if (string.IsNullOrWhiteSpace(q.VatNo)) throw new ArgumentNullException(nameof(q.VatNo));
            if (!int.TryParse(q.EntityNo, out var _)) throw new ArgumentNullException(nameof(q.EntityNo));
            var tokens = _hmrcToken.Resolve(q.VatNo);
            if (tokens == null)
                throw new HttpResponseException(HttpStatusCode.Unauthorized);

            var vatReturn = _vatReturnStore.GetVatReturnResponse(q.VatNo, q.PeriodKey);
            dynamic vatResponse = null;

            var vatReturnData = await _hmrcClient.GetVatReturn(q.VatNo, q.PeriodKey, tokens.AccessToken, Request);
            decimal[] vatData = vatReturnData.Data;
            var vatStringData = Array.ConvertAll(vatData, x => x.ToString(CultureInfo.InvariantCulture));
            var vatSubmissionData = new VatSubmissionRequest { EntityName = q.EntityName, EntityNo = q.EntityNo, FromDate = q.FromDate, ToDate = q.ToDate, PeriodKey = q.PeriodKey, VatNo = q.VatNo, VatValues = vatStringData };
            var guid = string.Empty;
            if (vatReturn != null)
            {
                vatResponse = JsonConvert.DeserializeObject<VatSuccesResponse>(vatReturn.Data);
                vatResponse.IsSuccessful = true;
                guid = _vatReturnExporter.ExportVatReturnToPdf(vatSubmissionData, vatResponse, true);
            }

            return new
            {
                VatResponse = vatResponse,
                VatReturnData = vatReturnData,
                PdfStorageId = guid
            };
        }

        [HttpGet]
        [Route("vatLogs")]
        public IEnumerable<dynamic> VatLogs([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] VatSubmissionRequest q)
        {
            var data = _vatReturnStore.GetLogData(q.VatNo, q.PeriodKey);
            var logs = data.Select(v => new { Date = v.LastModified, Message = JsonConvert.DeserializeObject(v.Data) });
            return logs;
        }

        VatReturnData GetVatData(VatSubmissionRequest vatData)
        {
            var data = new VatReturnData
            {
                PeriodKey = vatData.PeriodKey,
                VatDueSales = Convert.ToDecimal(vatData.VatValues[0]),
                VatDueAcquisitions = Convert.ToDecimal(vatData.VatValues[1]),
                TotalVatDue = Convert.ToDecimal(vatData.VatValues[2]),
                VatReclaimedCurrPeriod = Convert.ToDecimal(vatData.VatValues[3]),
                NetVatDue = Convert.ToDecimal(vatData.VatValues[4]),
                TotalValueSalesExVAT = Convert.ToDecimal(vatData.VatValues[5]),
                TotalValuePurchasesExVAT = Convert.ToDecimal(vatData.VatValues[6]),
                TotalValueGoodsSuppliedExVAT = Convert.ToDecimal(vatData.VatValues[7]),
                TotalAcquisitionsExVAT = Convert.ToDecimal(vatData.VatValues[8]),
                Finalised = true
            };

            return data;
        }

        async Task<dynamic> VatObligations(VatObligationsQuery q, string accessToken, string refreshToken, HttpRequestMessage requestHeaderValues)
        {
            var token = new AuthToken { AccessToken = accessToken, RefreshToken = refreshToken };
            var data = await _hmrcClient.RetrieveObligations(q, accessToken, requestHeaderValues);

            if (data.Status == HttpStatusCode.Unauthorized)
            {
                token = await _hmrcAuthenticator.RefreshToken(refreshToken, q.TaxNo);
                data = await _hmrcClient.RetrieveObligations(q, token.AccessToken, requestHeaderValues);
            }
            return new
            {
                Tokens = token,
                Data = data
            };
        }

        IEnumerable<EntityName> GetEntityNames()
        {
            var entities = new List<EntityName>();
            var candidates = from e in _dbContext.Set<SpecialName>()
                             join n in _dbContext.Set<Name>() on e.Id equals n.Id
                             where e.IsEntity.HasValue && e.IsEntity == 1
                             select new
                             {
                                 e.Id,
                                 Name = n,
                                 TaxCode = n.TaxNumber
                             };

            foreach (var candidate in candidates.ToArray())
            {
                entities.Add(new EntityName
                {
                    Id = candidate.Id,
                    DisplayName = candidate.Name.Formatted(),
                    TaxCode = candidate.TaxCode
                });
            }

            var orderedEntities = new List<EntityName>(entities.OrderBy(_ => _.DisplayName));
            return orderedEntities;
        }

        string GetDeviceId()
        {
            return _guidFactory().ToString();
        }

        public class EntityName
        {
            public int Id { get; set; }
            public string DisplayName { get; set; }
            public string TaxCode { get; set; }
        }
    }
}
