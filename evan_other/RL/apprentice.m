function [top_move,top_shift] = apprentice(starting_box,ground_truth)
%% Used for giving the reinforcement learning good examples for initial training epochs
%% Takes the current crop and ground and returns the best move and shift amount
    x = starting_box(1); y = starting_box(2); w = starting_box(3); h = starting_box(4);
    gx = ground_truth(1); gy = ground_truth(2); gw = ground_truth(3); gh = ground_truth(4);

%%  calculate distance between centers 
    xdiff = gx + gw/2 - x - w/2;
    ydiff = gy + gh/2 - y - h/2;
    
%%  maximum IOU threshold. Returns 1 (no change) as top move and 0 as shift amount
    IOU = bboxOverlapRatio(starting_box,ground_truth);
    if IOU > 0.75
        top_move = 1;
        top_shift = 0;
        return
    end

%% hor = horizantal move
    hor = 4;
    if xdiff > 0 
        hor = 5;
    end

%% v = vertical move
    v = 3;
    if ydiff > 0
        v = 2;
    end
   
%%  resize = 0 indicates that neither shrink nor expand are good moves  
    resize = 0;
    shift = 0;

%% shrink vs expand is currently based on the larger of the two ground truth axes
%% example, if groun width is larger than ground height, all crops with smallers widths are classifed as shrink
    if gw > gh
        if (x < gx && x + w > gx + gw)
            resize = 7;
            shift = gw/w - 1;
        elseif (x > gx && x + w < gx + gw )
            resize = 6;
            shift = 1 - gw/w;
        end
    else
        if (y < gy && y + h > gy + gh)
            resize = 7;
            shift = gh/h - 1;
        elseif (y > gy && y + h < gy + gh)
            resize = 6;
            shift = 1 - gh/h;
        end
    end
    
    xshift = round(abs(xdiff)/w,1);
    yshift = round(abs(ydiff)/h,1);
    eshift = round(abs(shift),1);
    
%% best move is judged as largest percent change of relative dimension

    [top_shift, biggest_ind] = max([xshift,yshift,eshift]);
    
    if biggest_ind == 1
        top_move = hor;
    elseif biggest_ind == 2
        top_move = v;
    elseif biggest_ind == 3 && resize ~= 0
        top_move = resize;
    end
		



