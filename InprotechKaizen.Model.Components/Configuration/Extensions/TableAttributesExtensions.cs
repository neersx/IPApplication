using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Components.Configuration.Extensions
{
    public static class TableAttributesExtensions
    {
        public static IEnumerable<TableAttributes> For(this IEnumerable<TableAttributes> set, Case @case)
        {
            if(@case == null) throw new ArgumentNullException("case");

            return
                set.Where(
                          ta =>
                          ta.ParentTable == KnownTableAttributes.Case && @case.Id.ToString(CultureInfo.InvariantCulture) == ta.GenericKey);
        }

        public static IEnumerable<TableAttributes> For(this IEnumerable<TableAttributes> set, Name name)
        {
            if (name == null) throw new ArgumentNullException("name");

            return
                set.Where(
                          ta =>
                          ta.ParentTable == KnownTableAttributes.Name && name.Id.ToString(CultureInfo.InvariantCulture) == ta.GenericKey);
        }

        public static IEnumerable<TableAttributes> For(this IEnumerable<TableAttributes> set, Country country)
        {
            if (country == null) throw new ArgumentNullException("country");

            return
                set.Where(
                          ta =>
                          ta.ParentTable == KnownTableAttributes.Country && country.Id.ToString(CultureInfo.InvariantCulture) == ta.GenericKey);
        }

        public static IEnumerable<TableAttributes> FilterBy(this IEnumerable<TableAttributes> set, TableTypes type)
        {
            return
                set.Where(ta => ta.SourceTableId == (short)type);
        }
    }
}