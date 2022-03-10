using System;
using System.Collections.ObjectModel;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Components.Names;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class CaseNameRestrictionModel
    {
        public CaseNameRestrictionModel(
            CaseName caseName,
            short[] debtorRestrictionActions,
            bool forExceedingCreditLimit)
        {
            if(caseName == null) throw new ArgumentNullException("caseName");
            if(debtorRestrictionActions == null) throw new ArgumentNullException("debtorRestrictionActions");

            FormattedName = caseName.Name.Formatted();
            NameTypeDescription = caseName.NameType.Name;
            Restrictions = new Collection<RestrictionDetailsModel>();

            if(caseName.HasDebtorRestrictions(debtorRestrictionActions))
                Restrictions.Add(RestrictionDetailsModel.For(caseName.Name.ClientDetail.DebtorStatus));

            if(forExceedingCreditLimit)
                Restrictions.Add(RestrictionDetailsModel.ForExceededCreditLimit());
        }

        public string FormattedName { get; private set; }
        public string NameTypeDescription { get; private set; }
        public Collection<RestrictionDetailsModel> Restrictions { get; private set; }
    }
}