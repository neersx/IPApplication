using System;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Configuration.SiteControl;

namespace InprotechKaizen.Model.Components.Configuration.Extensions
{
    public static class SiteControlExtensions
    {
        public static bool RequiresPasswordOnConfirmation(this IDbSet<Model.Configuration.SiteControl.SiteControl> set)
        {
            return set.Any(sc => sc.ControlId == SiteControls.ConfirmationPasswd && !string.IsNullOrEmpty(sc.StringValue));
        }

        [SuppressMessage("Microsoft.Usage", "CA1801:ReviewUnusedParameters", MessageId = "siteControl")]
        public static string GetDataTypeName(this ISiteControlDataTypeFormattable siteControl, string dataType)
        {
            switch (dataType)
            {
                case "I":
                    return "Integer";
                case "D":
                    return "Decimal";
                case "C":
                    return "String";
                case "B":
                    return "Boolean";
            }

            return null;
        }

        public static object GetValue(this ISiteControlDataTypeFormattable siteControl, string dataType)
        {
            if (siteControl == null) throw new ArgumentNullException(nameof(siteControl));

            switch (dataType)
            {
                case "I":
                    return siteControl.IntegerValue;
                case "D":
                    return siteControl.DecimalValue;
                case "C":
                    return siteControl.StringValue;
                case "B":
                    return siteControl.BooleanValue;
            }

            return (object) siteControl.IntegerValue ??
                   (object) siteControl.DecimalValue ??
                   (object) siteControl.BooleanValue ??
                   siteControl.StringValue;
        }

        public static void UpdateValue(this Model.Configuration.SiteControl.SiteControl siteControl, object value)
        {
            if (siteControl == null) throw new ArgumentNullException(nameof(siteControl));

            switch (siteControl.DataType)
            {
                case "I":
                    if (value == null)
                    {
                        siteControl.IntegerValue = null;
                    }
                    else
                    {
                        siteControl.IntegerValue = Convert.ToInt32(value);
                    }
                    break;
                case "D":
                    if (value == null)
                    {
                        siteControl.DecimalValue = null;
                    }
                    else
                    {
                        siteControl.DecimalValue = Convert.ToDecimal(value);
                    }
                    break;
                case "B":
                    if (value == null)
                    {
                        siteControl.BooleanValue = null;
                    }
                    else
                    {
                        siteControl.BooleanValue = Convert.ToBoolean(value);
                    }
                    break;
                case "C":
                    siteControl.StringValue = value == null ? null : Convert.ToString(value);
                    break;
            }
        }
    }
}