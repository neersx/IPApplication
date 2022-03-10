using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Components.Names.Extensions
{
    public static class NameExtensions
    {
        public static IEnumerable<NameVariant> AvailableNameVariantsForCase(this Name name, Case @case)
        {
            if(name == null) throw new ArgumentNullException("name");
            if(@case == null) throw new ArgumentNullException("case");

            return name.NameVariants
                       .Where(nv => (@case.PropertyType.Equals(nv.PropertyType) || nv.PropertyType == null));
        }
    }
}