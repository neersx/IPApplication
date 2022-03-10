export let jsonUtilities = {
    splitKeyedJSONObject: (obj: any) => {
        const newObj = {};
        if (!obj) {
            return null;
        }
        Object.keys(obj).forEach((k) => {
            const prop = k.split('.');
            if (prop.length > 1) {
                const last = prop.pop();
                prop.reduce((o, key) => {
                    const val = (key !== last ? o[key] : null) || obj[key] || {};

                    return o[key] = val;
                }, newObj)[last] = obj[k];
            } else {
                newObj[k] = obj[k];
            }
        });

        return newObj;
    }
};