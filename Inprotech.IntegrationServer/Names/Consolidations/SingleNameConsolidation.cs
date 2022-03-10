using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Names.Consolidation;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations
{
    public class SingleNameConsolidation : ISingleNameConsolidation
    {
        readonly IDbContext _dbContext;
        readonly ITransactionRecordal _transactionRecordal;
        readonly IConsolidatorProvider _consolidatorProvider;
        readonly IConsolidationSettings _consolidationSettings;
        readonly IDerivedAttention _derivedAttention;
        readonly Func<DateTime> _systemClock;

        public SingleNameConsolidation(IDbContext dbContext, 
                                       ITransactionRecordal transactionRecordal, 
                                       IConsolidatorProvider consolidatorProvider, 
                                       IConsolidationSettings consolidationSettings,
                                       IDerivedAttention derivedAttention,
                                       Func<DateTime> systemClock)
        {
            _dbContext = dbContext;
            _transactionRecordal = transactionRecordal;
            _consolidatorProvider = consolidatorProvider;
            _consolidationSettings = consolidationSettings;
            _derivedAttention = derivedAttention;
            _systemClock = systemClock;
        }

        public async Task Consolidate(int executeAs, int from, int to, bool keepAddressHistory, bool keepTelecomHistory, bool keepConsolidatedName)
        {
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled, commandTimeout: _consolidationSettings.Timeout))
            {
                var names = await _dbContext.Set<Name>()
                                            .Where(_ => _.Id == to || _.Id == from)
                                            .ToDictionaryAsync(k => k.Id, v => v);

                if (!names.ContainsKey(to) || !names.ContainsKey(from))
                {
                    tcs.Complete();
                    return;
                }

                var executeAsUser = _dbContext.Set<User>().Single(_ => _.Id == executeAs);

                var option = new ConsolidationOption(keepAddressHistory, keepTelecomHistory, keepConsolidatedName);

                _transactionRecordal.ExecuteTransactionFor(executeAsUser, names[to], NameTransactionMessageIdentifier.AmendedName);

                await KeepTrackOfNameReplaced(names[to], names[from]);

                foreach(var consolidator in _consolidatorProvider.Provide())
                    await consolidator.Consolidate(names[to], names[from], option);

                await PostProcessingConsolidatedName(names[from], keepConsolidatedName);

                await _derivedAttention.Recalculate(executeAs, names[to].Id);

                tcs.Complete();
            }
        }

        async Task PostProcessingConsolidatedName(Name consolidatedName, bool keepConsolidatedName)
        {
            if (keepConsolidatedName)
            {
                consolidatedName.DateCeased = _systemClock().Date;
            }
            else
            {
                _dbContext.Set<Name>().Remove(consolidatedName);
            }

            await _dbContext.SaveChangesAsync();
        }

        async Task KeepTrackOfNameReplaced(Name to, Name from)
        {
            if (!await _dbContext.Set<NameReplaced>().AnyAsync(_ => _.NewNameNo == to.Id && _.OldNameNo == from.Id))
            {
                _dbContext.Set<NameReplaced>()
                          .Add(new NameReplaced
                          {
                              NewNameNo = to.Id,
                              OldNameNo = from.Id
                          });

                await _dbContext.SaveChangesAsync();
            }
        }
    }
}