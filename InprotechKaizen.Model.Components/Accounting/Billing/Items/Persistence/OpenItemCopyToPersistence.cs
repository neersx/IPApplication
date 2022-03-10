using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public class OpenItemCopyToPersistence : INewDraftBill, IUpdateDraftBill
    {
        readonly IDbContext _dbContext;
        readonly IExactNameAddressSnapshot _exactNameAddressSnapshot;
        readonly ILogger<OpenItemCopyToPersistence> _logger;

        public OpenItemCopyToPersistence(IDbContext dbContext, 
                                         IExactNameAddressSnapshot exactNameAddressSnapshot,
                                         ILogger<OpenItemCopyToPersistence> logger)
        {
            _dbContext = dbContext;
            _exactNameAddressSnapshot = exactNameAddressSnapshot;
            _logger = logger;
        }

        public Stage Stage => Stage.SaveOpenItemCopiesTo;
        
        public void SetLogContext(Guid contextId)
        {
            _logger.SetContext(contextId);    
        }

        public async Task<bool> Run(int userIdentityId, string culture, BillingSiteSettings settings, OpenItemModel model, SaveOpenItemResult result)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));
            if (result == null) throw new ArgumentNullException(nameof(result));
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null || model.ItemTransactionId == null || model.AccountEntityId == null)
            {
                throw new ArgumentException($"{nameof(model.ItemEntityId)}, {nameof(model.ItemTransactionId)} and {nameof(model.AccountEntityId)} must all have a value.");
            }

            if (!model.Debtors.Any(_ => _.HasCopyToDataChanged)) return true;

            foreach (var debtor in model.Debtors)
            {
                foreach (var copiesTo in debtor.CopiesTos)
                {
                    if (copiesTo.IsDeletedCopyToName)
                    {
                        continue;
                    }

                    var snapshotId = await _exactNameAddressSnapshot.Derive(
                                                                            new NameAddressSnapshotParameter
                                                                            {
                                                                                AccountDebtorId = copiesTo.CopyToNameId,
                                                                                AttentionNameId = copiesTo.ContactNameId,
                                                                                AddressId = copiesTo.AddressId,
                                                                                AddressChangeReasonId = copiesTo.AddressChangeReasonId,
                                                                                FormattedName = copiesTo.CopyToName,
                                                                                FormattedAttention = copiesTo.ContactName,
                                                                                FormattedAddress = copiesTo.Address
                                                                            });

                    await AddOpenItemCopyToIfRequired(debtor.NameId,
                                                      snapshotId,
                                                      (int)model.ItemEntityId,
                                                      (int)model.ItemTransactionId,
                                                      (int)model.AccountEntityId);

                    await DeleteUnreferencedNameAddressSnapshots(copiesTo.CopyToNameId);
                }
            }

            return true;
        }

        async Task DeleteUnreferencedNameAddressSnapshots(int copiesToNameId)
        {
            var openItems = _dbContext.Set<OpenItem>();
            var copiesTos = _dbContext.Set<OpenItemCopyTo>();

            var deleted = await _dbContext.DeleteAsync(from nas in _dbContext.Set<NameAddressSnapshot>()
                                                       join oi in openItems on nas.NameSnapshotId equals oi.NameSnapshotId into oi1
                                                       from oi in oi1.DefaultIfEmpty()
                                                       join ct in copiesTos on nas.NameSnapshotId equals ct.NameSnapshotId into ct1
                                                       from ct in ct1.DefaultIfEmpty()
                                                       where nas.NameId == copiesToNameId && oi == null && ct == null
                                                       select nas);

            _logger.Trace($"{nameof(DeleteUnreferencedNameAddressSnapshots)} # Deleted: NameAddressSnapshot={deleted}");
        }

        async Task AddOpenItemCopyToIfRequired(int debtorId, int snapshotId, int itemEntityId, int itemTransactionId, int accountEntityId)
        {
            if (!await _dbContext.Set<OpenItemCopyTo>().AnyAsync(_ => _.ItemEntityId == itemEntityId &&
                                                                      _.ItemTransactionId == itemTransactionId &&
                                                                      _.AccountEntityId == accountEntityId &&
                                                                      _.AccountDebtorId == debtorId &&
                                                                      _.NameSnapshotId == snapshotId
                                                                ))
            {
                var openItemCopyTo = _dbContext.Set<OpenItemCopyTo>().Add(new OpenItemCopyTo
                {
                    ItemEntityId = itemEntityId,
                    ItemTransactionId = itemTransactionId,
                    AccountEntityId = accountEntityId,
                    AccountDebtorId = debtorId,
                    NameSnapshotId = snapshotId
                });

                await _dbContext.SaveChangesAsync();

                _logger.Trace($"{nameof(AddOpenItemCopyToIfRequired)}", openItemCopyTo);
            }
        }
    }
}
