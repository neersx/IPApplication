using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;

namespace Inprotech.IntegrationServer.Names.Consolidations
{
    public interface IConsolidatorProvider
    {
        IEnumerable<INameConsolidator> Provide();
    }

    public class ConsolidatorProvider : IConsolidatorProvider
    {
        readonly Dictionary<string, INameConsolidator> _consolidators;

        public ConsolidatorProvider(IEnumerable<INameConsolidator> consolidators)
        {
            _consolidators = consolidators.ToDictionary(k => k.Name, v => v);
        }

        public IEnumerable<INameConsolidator> Provide()
        {
            foreach (var availableConsolidator in AvailableConsolidator)
            {
                var consolidator = _consolidators.Get(availableConsolidator);
                if (consolidator == null) continue;
                yield return consolidator;
            }
        }

        static readonly string[] AvailableConsolidator =
        {
            nameof(ClientDetailsConsolidator),
            nameof(CreditorConsolidator),
            nameof(IndividualConsolidator),
            nameof(NameAddressConsolidator),
            nameof(NameTelecomConsolidator),
            nameof(NameFilesInConsolidator),
            nameof(NameMainContactConsolidator),
            nameof(NameAliasConsolidator),
            nameof(NameImageConsolidator),
            nameof(NameTextConsolidator),
            nameof(AssociatedNameConsolidator),
            nameof(DiscountConsolidator),
            nameof(NameInstructionsConsolidator),
            nameof(NameLanguageConsolidator),
            nameof(OrganisationConsolidator),
            nameof(NameMarginProfileConsolidator),
            nameof(NameTypeClassificationConsolidator),
            nameof(SpecialNameConsolidator),
            nameof(TransactionHeaderConsolidator),
            nameof(AccountsConsolidator),
            nameof(BankConsolidator),
            nameof(AccessAccountNamesConsolidator),
            nameof(EmployeeReminderConsolidator),
            nameof(DiaryConsolidator),
            nameof(CaseNameConsolidator),
            nameof(FeesCalculationsConsolidator),
            nameof(AllOtherReferencesConsolidator)
        };
    }
}