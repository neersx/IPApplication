using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.CaseSupportData;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public interface ICaseDetailsSelectionVerification
    {
        CaseDetailsSelection Verify(CaseDetailsSelection selection);
    }

    public class CaseDetailsSelectionVerification : ICaseDetailsSelectionVerification
    {
        readonly IPropertyTypes _propertyTypes;
        readonly ICaseCategories _caseCategories;
        readonly ISubTypes _subTypes;
        readonly IBasis _basis;
        readonly IDictionary<string, Func<CaseDetailsSelection, CaseDetailsSelection>[]> _filters;

        public CaseDetailsSelectionVerification(
            IPropertyTypes propertyTypes,
            ICaseCategories caseCategories,
            ISubTypes subTypes,
            IBasis basis)
        {
            if(propertyTypes == null) throw new ArgumentNullException("propertyTypes");
            if(caseCategories == null) throw new ArgumentNullException("caseCategories");
            if(subTypes == null) throw new ArgumentNullException("subTypes");
            if(basis == null) throw new ArgumentNullException("basis");

            _propertyTypes = propertyTypes;
            _caseCategories = caseCategories;
            _subTypes = subTypes;
            _basis = basis;

            _filters = new Dictionary<string, Func<CaseDetailsSelection, CaseDetailsSelection>[]>
                       {
                           {
                               "Country",
                               new Func<CaseDetailsSelection, CaseDetailsSelection>[]
                               {
                                    VerifyPropertyTypes, VerifyCaseCategories, VerifySubTypes, VerifyBasisList
                               }
                           },
                           {
                               "CaseType",
                               new Func<CaseDetailsSelection, CaseDetailsSelection>[]
                               {
                                    VerifyCaseCategories, VerifySubTypes, VerifyBasisList
                               }
                           },
                           {
                               "PropertyType",
                               new Func<CaseDetailsSelection, CaseDetailsSelection>[]
                               {
                                    VerifyCaseCategories, VerifySubTypes, VerifyBasisList
                               }
                           },
                           {
                               "CaseCategory",
                               new Func<CaseDetailsSelection, CaseDetailsSelection>[]
                               {
                                    VerifySubTypes, VerifyBasisList
                               }
                           }
                       };
        }

        public CaseDetailsSelection Verify(CaseDetailsSelection selection)
        {
            if(selection == null) throw new ArgumentNullException("selection");

            return _filters[selection.ChangingField].Aggregate(selection, (input, next) => next(input));
        }

        CaseDetailsSelection VerifyPropertyTypes(CaseDetailsSelection selection)
        {
            if(!selection.PropertyTypes.Any())
                return selection;

            var countries = _propertyTypes.Get(null, selection.Countries);

            selection.PropertyTypes = countries
                        .Where(a => selection.PropertyTypes.Any(b => b.Key == a.Key)).ToArray();

            return selection;
        }

        CaseDetailsSelection VerifyCaseCategories(CaseDetailsSelection selection)
        {
            if(!selection.CaseCategories.Any())
                return selection;

            if(string.IsNullOrEmpty(selection.CaseType))
            {
                selection.CaseCategories = new KeyValuePair<string, string>[0];
                return selection;
            }

            var categories = _caseCategories.Get(
                                                 null,
                                                 selection.CaseType,
                                                 selection.Countries,
                                                 selection.PropertyTypes.Select(a => a.Key).ToArray());

            selection.CaseCategories =
                categories.Where(a => selection.CaseCategories.Any(b => b.Key == a.Key)).ToArray();

            return selection;
        }

        CaseDetailsSelection VerifySubTypes(CaseDetailsSelection selection)
        {
            var types = _subTypes.Get(
                                      selection.CaseType,
                                      selection.Countries,
                                      selection.PropertyTypes.Select(a => a.Key).ToArray(),
                                      selection.CaseCategories.Select(a => a.Key).ToArray());

            selection.SubTypes = types.ToArray();

            return selection;
        }

        CaseDetailsSelection VerifyBasisList(CaseDetailsSelection selection)
        {
            var basisList = _basis.Get(
                                         selection.CaseType,
                                         selection.Countries,
                                         selection.PropertyTypes.Select(a => a.Key).ToArray(),
                                         selection.CaseCategories.Select(a => a.Key).ToArray());

            selection.BasisList = basisList.ToArray();

            return selection;
        }
    }
}