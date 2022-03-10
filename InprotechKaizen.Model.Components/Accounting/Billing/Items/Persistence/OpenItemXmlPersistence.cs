using System;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;
using OpenItemXmlEntity = InprotechKaizen.Model.Accounting.OpenItem.OpenItemXml;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class OpenItemXmlPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IDbContext _dbContext;
        readonly ILogger<OpenItemXmlPersistence> _logger;

        public OpenItemXmlPersistence(IDbContext dbContext, ILogger<OpenItemXmlPersistence> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public Stage Stage => Stage.SaveOpenItemXml;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null || model.ItemTransactionId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)} and {nameof(model.ItemTransactionId)} must both have a value.");
            }

            var openItemXml = model.OpenItemXml.FirstOrDefault();
            if (openItemXml != null)
            {
                if (!TryParseOpenItemXml(openItemXml.ItemXml, result.RequestId, out var error))
                {
                    result.ErrorCode = KnownErrors.EBillingXmlInvalid;
                    result.ErrorDescription = error;

                    _logger.Warning($"{nameof(TryParseOpenItemXml)} alert={result.ErrorCode}/{result.ErrorDescription}");

                    return false;
                }

                await AddOpenItemXml((int)model.ItemEntityId, (int)model.ItemTransactionId, openItemXml);
            }

            return true;
        }

        async Task AddOpenItemXml(int itemEntityId, int itemTransactionId, OpenItemXml openItemXml)
        {
            var openItemXmlEntity = _dbContext.Set<OpenItemXmlEntity>()
                                              .Add(new OpenItemXmlEntity
                                              {
                                                  ItemEntityId = itemEntityId,
                                                  ItemTransactionId = itemTransactionId,
                                                  XmlType = (OpenItemXmlType)openItemXml.XmlType,
                                                  OpenItemXmlValue = openItemXml.ItemXml
                                              });

            await _dbContext.SaveChangesAsync();

            _logger.Trace("InsertOpenItemXml", openItemXmlEntity);
        }

        bool TryParseOpenItemXml(string xml, Guid requestId, out string error)
        {
            try
            {
                error = null;
                var _ = XElement.Parse(xml);
                return true;
            }
            catch (Exception e)
            {
                _logger.Exception(e, $"{nameof(TryParseOpenItemXml)}");
                error = e.Message;
                return false;
            }
        }
    }
}
