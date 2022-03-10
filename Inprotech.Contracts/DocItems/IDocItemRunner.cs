using System;
using System.Collections.Generic;
using System.Data;

namespace Inprotech.Contracts.DocItems
{
    public interface IDocItemRunner
    {
        DataSet Run(int docItemId, IDictionary<string, object> parameters, Action<object> docItemAction = null);

        DataSet Run(string docItemName, IDictionary<string, object> parameters);
    }
}