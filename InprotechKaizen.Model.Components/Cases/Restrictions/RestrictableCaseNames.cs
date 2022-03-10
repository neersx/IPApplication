using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Components.Cases.Restrictions
{
    public interface IRestrictableCaseNames
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "For")]
        IEnumerable<CaseName> For(Case @case);
    }

    public class RestrictableCaseNames : IRestrictableCaseNames
    {
        readonly ICurrentNames _currentNames;
        
        public RestrictableCaseNames(ICurrentNames currentNames)
        {
            if (currentNames == null) throw new ArgumentNullException("currentNames");
            _currentNames = currentNames;
        }

        public IEnumerable<CaseName> For(Case @case)
        {
            if(@case == null) throw new ArgumentNullException("case");

            return _currentNames.For(@case).Where(
                                         cn => cn.NameType.IsNameRestricted == 1 &&
                                               cn.Name.ClientDetail != null);
        }
    }
}