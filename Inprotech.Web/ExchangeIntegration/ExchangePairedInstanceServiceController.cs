using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Transactions;
using System.Web.Http;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Integration.Analytics;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Web.ExchangeIntegration
{
    /// <summary>
    /// For Release 16 only
    /// </summary>
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/exchange/paired-instance-requests")]
    public class ExchangePairedInstanceServiceController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IExchangeIntegrationQueue _exchangeIntegrationQueue;
        readonly IExchangePairedInstanceRequestValidator _requestValidator;
        readonly IBus _bus;
        readonly ICapabilitiesResolver _deliveryCapabilitiesResolver;
        readonly ISecurityContext _securityContext;

        public ExchangePairedInstanceServiceController(IDbContext dbContext, IExchangeIntegrationQueue exchangeIntegrationQueue, ISecurityContext securityContext,
                                                       IExchangePairedInstanceRequestValidator requestValidator, IBus bus, ICapabilitiesResolver deliveryCapabilitiesResolver)
        {
            _dbContext = dbContext;
            _exchangeIntegrationQueue = exchangeIntegrationQueue;
            _securityContext = securityContext;
            _requestValidator = requestValidator;
            _bus = bus;
            _deliveryCapabilitiesResolver = deliveryCapabilitiesResolver;
        }

        [HttpGet]
        [Route("enabled")]
        public async Task<bool> GetExchangeSettings()
        {
            return (await _deliveryCapabilitiesResolver.Resolve()).CanDeliverBillInDraftMailbox;
        }

        [HttpPost]
        [Route("create")]
        public async Task<HttpResponseMessage> UploadDocument()
        {
            if (!Request.Content.IsMimeMultipartContent())
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            var provider = new MultipartMemoryStreamProvider();

            await Request.Content.ReadAsMultipartAsync(provider);

            var model = await ExtractRequestParameters(provider);

            if (!_requestValidator.ValidateMailbox(_securityContext.User.Id, model.Mailbox))
            {
                throw new HttpResponseException(HttpStatusCode.Unauthorized);
            }

            var attachments = new List<EmailAttachment>();

            for (var i = 1; i < provider.Contents.Count; i++)
            {
                var attachment = await ExtractAttachment(provider.Contents[i]);
                if (attachment != null)
                {
                    attachments.Add(attachment);
                }
            }

            await SaveToExchangeRequestQueue(model, attachments);

            await _bus.PublishAsync(new TransactionalAnalyticsMessage
            {
                EventType = TransactionalEventTypes.ExchangeEmailDraftViaApi,
                Value = "1"
            });

            return new HttpResponseMessage
            {
                Content = new StringContent(JsonConvert.SerializeObject(new
                {
                    Status = true,
                    Message = $"{provider.Contents.Count}|File uploaded."
                }))
            };
        }

        async Task<ExchangeRequestModel> ExtractRequestParameters(MultipartMemoryStreamProvider provider)
        {
            if (provider.Contents.Count == 0)
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            var param = await provider.Contents[0].ReadAsStringAsync();
            var decoded = WebUtility.UrlDecode(param);
            var paramArr = decoded.Split(new[] { '=' }, 2);
            if (paramArr.Length == 2 && paramArr[0] == "params")
            {
                var data = JsonConvert.DeserializeObject<ExchangeRequestModel>(paramArr[1]);
                if (data.IsValid()) return data;
            }

            throw new HttpResponseException(HttpStatusCode.BadRequest);
        }

        async Task<EmailAttachment> ExtractAttachment(HttpContent item)
        {
            if (item.Headers.ContentDisposition.FileName != null)
            {
                using var ms = await item.ReadAsStreamAsync();
                using var br = new BinaryReader(ms);

                if (ms.Length <= 0)
                {
                    throw new HttpResponseException(HttpStatusCode.BadRequest);
                }

                var data = br.ReadBytes((int)ms.Length);

                ms.Seek(0, SeekOrigin.Begin);
                if (!_requestValidator.ValidateFileExtension(ms))
                {
                    throw new HttpResponseException(HttpStatusCode.BadRequest);
                }

                return new EmailAttachment
                {
                    FileName = item.Headers.ContentDisposition.FileName,
                    Content = Convert.ToBase64String(data)
                };
            }

            return null;
        }

        async Task SaveToExchangeRequestQueue(ExchangeRequestModel model, List<EmailAttachment> attachments)
        {
            var draft = new DraftEmailProperties
            {
                Subject = model.EmailSubject,
                Body = model.EmailBody,
                IsBodyHtml = model.IsBodyHtml,
                Mailbox = model.Mailbox,
                Attachments = attachments
            };
            draft.Recipients.Add(model.EmailToAddress);
            draft.CcRecipients.Add(model.EmailCcAddress);

            using var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);
            
            await _exchangeIntegrationQueue.QueueDraftEmailRequest(draft, model.CaseKey, (_securityContext.User.NameId, _securityContext.User.Id));

            await _dbContext.SaveChangesAsync();

            tcs.Complete();
        }

        public class ExchangeRequestModel
        {
            public string Mailbox { get; set; }
            public string EmailToAddress { get; set; }
            public string EmailCcAddress { get; set; }
            public string EmailSubject { get; set; }
            public string EmailBody { get; set; }
            public string AttachmentName { get; set; }
            public string Extension { get; set; }
            public bool IsBodyHtml { get; set; }
            public int? CaseKey { get; set; }

            public bool IsValid()
            {
                return !string.IsNullOrEmpty(Mailbox);
            }
        }
    }
}