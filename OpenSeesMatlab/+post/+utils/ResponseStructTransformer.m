classdef ResponseStructTransformer
    %RESPONSESTRUCTTRANSFORMER Align model-update response struct arrays.
    %
    % Converts a response struct array returned by getNodalResponse or
    % getElementResponse into one scalar struct. Time rows are concatenated,
    % nodeTags/eleTags are merged, and response arrays are aligned to the
    % merged tags with NaN padding for tags absent in a segment.

    methods (Static)
        function out = merge(respData)
            if isempty(respData)
                out = struct();
                return;
            end

            if ~isstruct(respData)
                error('ResponseStructTransformer:InvalidInput', ...
                    'Input must be a response struct or struct array.');
            end

            if isscalar(respData)
                out = respData;
                return;
            end

            parts = num2cell(respData(:));
            ctx = struct('nodeTags', [], 'eleTags', [], ...
                'nodeTagsParts', {{}}, 'eleTagsParts', {{}});
            out = post.utils.ResponseStructTransformer.mergeStructParts(parts, ctx);
        end
    end

    methods (Static, Access = private)
        function out = mergeStructParts(parts, parentCtx)
            parts = parts(~cellfun(@isempty, parts));
            if isempty(parts)
                out = struct();
                return;
            end

            fns = post.utils.ResponseStructTransformer.unionFieldnames(parts);
            nPart = numel(parts);
            steps = post.utils.ResponseStructTransformer.countPartSteps(parts);

            localNodeTags = post.utils.ResponseStructTransformer.getPartTags(parts, 'nodeTags');
            localEleTags = post.utils.ResponseStructTransformer.getPartTags(parts, 'eleTags');

            if any(~cellfun(@isempty, localNodeTags))
                nodeCtx = post.utils.ResponseStructTransformer.stableUnion(localNodeTags);
                nodeTagsParts = localNodeTags;
            else
                nodeCtx = parentCtx.nodeTags;
                nodeTagsParts = parentCtx.nodeTagsParts;
            end

            if any(~cellfun(@isempty, localEleTags))
                eleCtx = post.utils.ResponseStructTransformer.stableUnion(localEleTags);
                eleTagsParts = localEleTags;
            else
                eleCtx = parentCtx.eleTags;
                eleTagsParts = parentCtx.eleTagsParts;
            end

            childCtx = struct('nodeTags', nodeCtx, 'eleTags', eleCtx, ...
                'nodeTagsParts', {nodeTagsParts}, 'eleTagsParts', {eleTagsParts});
            out = struct();

            for i = 1:numel(fns)
                name = fns{i};
                values = cell(nPart, 1);
                for p = 1:nPart
                    if isfield(parts{p}, name)
                        values{p} = parts{p}.(name);
                    end
                end

                switch name
                    case 'time'
                        out.(name) = post.utils.ResponseStructTransformer.mergeTime(values, steps);
                    case 'nodeTags'
                        out.(name) = nodeCtx(:);
                    case 'eleTags'
                        out.(name) = eleCtx(:);
                    otherwise
                        out.(name) = post.utils.ResponseStructTransformer.mergeValues( ...
                            values, steps, childCtx);
                end
            end
        end

        function out = mergeValues(values, steps, ctx)
            idx = find(~cellfun(@isempty, values), 1, 'first');
            if isempty(idx)
                out = [];
                return;
            end

            first = values{idx};
            if isstruct(first)
                structParts = cell(size(values));
                for i = 1:numel(values)
                    if isstruct(values{i})
                        structParts{i} = values{i};
                    else
                        structParts{i} = struct();
                    end
                end
                out = post.utils.ResponseStructTransformer.mergeStructParts(structParts, ctx);
                return;
            end

            if isnumeric(first) || islogical(first)
                out = post.utils.ResponseStructTransformer.mergeNumeric(values, steps, ctx);
                return;
            end

            out = first;
        end

        function out = mergeNumeric(values, steps, ctx)
            tagKind = post.utils.ResponseStructTransformer.inferTagKind(values, ctx);
            switch tagKind
                case 'node'
                    out = post.utils.ResponseStructTransformer.mergeTaggedNumeric( ...
                        values, steps, ctx.nodeTags, ctx.nodeTagsParts);
                case 'ele'
                    out = post.utils.ResponseStructTransformer.mergeTaggedNumeric( ...
                        values, steps, ctx.eleTags, ctx.eleTagsParts);
                otherwise
                    out = post.utils.ResponseStructTransformer.mergeTimeNumeric(values, steps);
            end
        end

        function kind = inferTagKind(values, ctx)
            kind = '';
            idx = find(~cellfun(@isempty, values));
            if isempty(idx)
                return;
            end

            nodeMatch = false;
            eleMatch = false;
            for k = 1:numel(idx)
                x = values{idx(k)};
                if ~(isnumeric(x) || islogical(x)) || isempty(x) || ndims(x) < 2
                    continue;
                end
                nodeTags = post.utils.ResponseStructTransformer.partTagsAt(ctx.nodeTagsParts, idx(k));
                eleTags = post.utils.ResponseStructTransformer.partTagsAt(ctx.eleTagsParts, idx(k));
                if ~isempty(nodeTags) && size(x, 2) == numel(nodeTags)
                    nodeMatch = true;
                end
                if ~isempty(eleTags) && size(x, 2) == numel(eleTags)
                    eleMatch = true;
                end
            end

            if eleMatch && ~nodeMatch
                kind = 'ele';
            elseif nodeMatch && ~eleMatch
                kind = 'node';
            elseif eleMatch
                kind = 'ele';
            end
        end

        function out = mergeTaggedNumeric(values, steps, tagsUnion, tagsParts)
            nStep = sum(steps);
            nTag = numel(tagsUnion);
            maxTail = post.utils.ResponseStructTransformer.maxTailSize(values);
            out = post.utils.ResponseStructTransformer.nanArray([nStep, nTag], maxTail);

            row0 = 0;
            for p = 1:numel(values)
                x = values{p};
                nLocalStep = steps(p);
                if isempty(x) || nLocalStep == 0
                    row0 = row0 + nLocalStep;
                    continue;
                end

                localTags = post.utils.ResponseStructTransformer.partTagsAt(tagsParts, p);
                if isempty(localTags)
                    localTags = tagsUnion;
                end

                x = double(x);
                sx = size(x);
                if numel(sx) < 2
                    sx(2) = 1;
                end
                [tf, loc] = ismember(double(localTags(:)), double(tagsUnion(:)));
                valid = tf & loc > 0 & (1:numel(localTags)).' <= sx(2);
                nRows = min(nLocalStep, sx(1));
                rows = row0 + (1:nRows);
                if isempty(rows)
                    row0 = row0 + nLocalStep;
                    continue;
                end

                srcCols = find(valid);
                dstCols = loc(valid);
                out = post.utils.ResponseStructTransformer.writeTaggedBlock( ...
                    out, x, rows, 1:nRows, srcCols, dstCols);
                row0 = row0 + nLocalStep;
            end
        end

        function out = mergeTimeNumeric(values, steps)
            if ~post.utils.ResponseStructTransformer.isTimeNumeric(values, steps)
                out = post.utils.ResponseStructTransformer.firstNonEmpty(values);
                return;
            end

            nStep = sum(steps);
            maxTail = post.utils.ResponseStructTransformer.maxTailSize(values);
            out = post.utils.ResponseStructTransformer.nanArray(nStep, maxTail);
            row0 = 0;
            for p = 1:numel(values)
                x = values{p};
                nLocalStep = steps(p);
                if isempty(x) || nLocalStep == 0
                    row0 = row0 + nLocalStep;
                    continue;
                end
                x = double(x);
                sx = size(x);
                nRows = min(nLocalStep, sx(1));
                rows = row0 + (1:nRows);
                out = post.utils.ResponseStructTransformer.writeTimeBlock(out, x, rows, 1:nRows);
                row0 = row0 + nLocalStep;
            end
        end

        function tf = isTimeNumeric(values, steps)
            tf = false;
            idx = find(~cellfun(@isempty, values));
            for k = 1:numel(idx)
                p = idx(k);
                x = values{p};
                if (isnumeric(x) || islogical(x)) && ~isempty(x) && ...
                        steps(p) > 0 && size(x, 1) == steps(p)
                    tf = true;
                    return;
                end
            end
        end

        function out = mergeTime(values, steps)
            out = nan(sum(steps), 1);
            pos = 1;
            for p = 1:numel(values)
                n = steps(p);
                if n == 0
                    continue;
                end
                if ~isempty(values{p})
                    t = double(values{p}(:));
                    nCopy = min(n, numel(t));
                    out(pos:pos+nCopy-1) = t(1:nCopy);
                end
                pos = pos + n;
            end
        end

        function steps = countPartSteps(parts)
            steps = zeros(numel(parts), 1);
            for p = 1:numel(parts)
                s = parts{p};
                if isfield(s, 'time') && ~isempty(s.time)
                    steps(p) = numel(s.time);
                else
                    steps(p) = post.utils.ResponseStructTransformer.findStepCount(s);
                end
            end
        end

        function n = findStepCount(s)
            n = 0;
            if ~isstruct(s)
                return;
            end
            fns = fieldnames(s);
            for i = 1:numel(fns)
                name = fns{i};
                if any(strcmp(name, {'nodeTags', 'eleTags', 'odbTag', 'eleType'}))
                    continue;
                end
                v = s.(name);
                if isstruct(v)
                    n = post.utils.ResponseStructTransformer.findStepCount(v);
                elseif (isnumeric(v) || islogical(v)) && ~isempty(v) && ndims(v) >= 2
                    n = size(v, 1);
                end
                if n > 0
                    return;
                end
            end
        end

        function tags = getPartTags(parts, fieldName)
            tags = cell(numel(parts), 1);
            for p = 1:numel(parts)
                if isfield(parts{p}, fieldName) && ~isempty(parts{p}.(fieldName))
                    raw = parts{p}.(fieldName);
                    tags{p} = double(raw(:));
                else
                    tags{p} = [];
                end
            end
        end

        function out = stableUnion(values)
            out = zeros(0, 1);
            for i = 1:numel(values)
                v = double(values{i}(:));
                v = v(isfinite(v));
                for j = 1:numel(v)
                    if ~ismember(v(j), out)
                        out(end + 1, 1) = v(j); %#ok<AGROW>
                    end
                end
            end
        end

        function fns = unionFieldnames(parts)
            fns = {};
            for p = 1:numel(parts)
                if ~isstruct(parts{p})
                    continue;
                end
                names = fieldnames(parts{p});
                for i = 1:numel(names)
                    if ~ismember(names{i}, fns)
                        fns{end + 1, 1} = names{i}; %#ok<AGROW>
                    end
                end
            end
        end

        function tail = maxTailSize(values)
            tail = [];
            for i = 1:numel(values)
                x = values{i};
                if isempty(x) || ~(isnumeric(x) || islogical(x))
                    continue;
                end
                sx = size(x);
                if numel(sx) <= 2
                    cur = [];
                else
                    cur = sx(3:end);
                end
                if isempty(tail)
                    tail = cur;
                else
                    tail = post.utils.ResponseStructTransformer.maxShape(tail, cur);
                end
            end
        end

        function out = writeTaggedBlock(out, x, dstRows, srcRows, srcCols, dstCols)
            sx = size(x);
            if numel(sx) < ndims(out)
                sx(end+1:ndims(out)) = 1;
            end
            for i = 1:numel(srcCols)
                src = srcCols(i);
                dst = dstCols(i);
                if src > size(x, 2)
                    continue;
                end
                srcSubs = [{srcRows}, {src}];
                dstSubs = [{dstRows}, {dst}];
                for d = 3:ndims(out)
                    n = min(size(out, d), sx(d));
                    srcSubs{d} = 1:n;
                    dstSubs{d} = 1:n;
                end
                out(dstSubs{:}) = x(srcSubs{:});
            end
        end

        function out = writeTimeBlock(out, x, dstRows, srcRows)
            sx = size(x);
            if numel(sx) < ndims(out)
                sx(end+1:ndims(out)) = 1;
            end
            srcSubs = {srcRows};
            dstSubs = {dstRows};
            for d = 2:ndims(out)
                n = min(size(out, d), sx(d));
                srcSubs{d} = 1:n;
                dstSubs{d} = 1:n;
            end
            out(dstSubs{:}) = x(srcSubs{:});
        end

        function s = maxShape(a, b)
            a = double(a);
            b = double(b);
            if numel(a) < numel(b)
                a(end+1:numel(b)) = 1;
            elseif numel(b) < numel(a)
                b(end+1:numel(a)) = 1;
            end
            s = max(a, b);
        end

        function tags = partTagsAt(tagsParts, idx)
            tags = [];
            if iscell(tagsParts) && idx <= numel(tagsParts)
                tags = tagsParts{idx};
            end
        end

        function out = nanArray(leading, tail)
            shape = double(leading);
            if ~isempty(tail)
                shape = [shape, double(tail)];
            end
            out = nan(shape);
        end

        function out = firstNonEmpty(values)
            out = [];
            for i = 1:numel(values)
                if ~isempty(values{i})
                    out = values{i};
                    return;
                end
            end
        end
    end
end
